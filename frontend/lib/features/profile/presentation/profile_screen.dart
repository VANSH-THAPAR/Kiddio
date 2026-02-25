import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // Add Geolocator
import 'package:image_picker/image_picker.dart'; // Add Image Picker
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iconsax/iconsax.dart'; // Add Iconsax
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart'; // Add theme provider
import '../../auth/models/user_model.dart';
import '../../auth/models/child_model.dart';
import '../../auth/providers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _yearsController;
  late TextEditingController _addressController;
  late TextEditingController _profileImageController;
  List<ChildModel> _children = [];

  bool _isEditing = false;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      // Upload to Cloudinary
      String cloudName = '';
      String uploadPreset = '';
      
      try {
        cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
        uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      } catch (e) {
        throw Exception("Failed to load environment variables. Please restart the app.");
      }
      
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception("Cloudinary configuration missing in .env file");
      }
      
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(pickedFile.path, resourceType: CloudinaryResourceType.Image),
      );
      
      final String downloadUrl = response.secureUrl;

      if (mounted) {
        setState(() {
          _profileImageController.text = downloadUrl;
          _isUploadingImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully! Click save to apply.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _hourlyRateController = TextEditingController(text: user?.hourlyRate?.toString() ?? '');
    _yearsController = TextEditingController(text: user?.yearsOfExperience?.toString() ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _profileImageController = TextEditingController(text: user?.profileImage ?? '');
    _children = List.from(user?.children ?? []);
    _latitude = user?.latitude;
    _longitude = user?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _yearsController.dispose();
    _addressController.dispose();
    _profileImageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permissions are permanently denied, we cannot request permissions.')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      // Update local state immediately
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      // Auto-save location immediately so feedback is instant
      if (mounted) {
        final currentUser = ref.read(authControllerProvider).user;
        if (currentUser != null) {
          await ref.read(authControllerProvider.notifier).updateProfile(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated and saved to profile.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _showChildDialog({ChildModel? childToEdit, int? index}) async {
    final nameController = TextEditingController(text: childToEdit?.name ?? '');
    DateTime selectedDate = childToEdit?.dob ?? DateTime.now();
    String gender = childToEdit?.gender ?? 'Male'; // Default
    final specialNeedsController = TextEditingController(text: childToEdit?.specialNeeds ?? '');
    final allergiesController = TextEditingController(text: childToEdit?.allergies ?? '');
    final notesController = TextEditingController(text: childToEdit?.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(childToEdit == null ? Iconsax.add_circle : Iconsax.edit, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(childToEdit == null ? "Add Child" : "Edit Details"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    prefixIcon: const Icon(Iconsax.user),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      prefixIcon: const Icon(Iconsax.calendar),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Iconsax.profile_2user),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => gender = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialNeedsController,
                  decoration: InputDecoration(
                    labelText: "Special Needs (Optional)",
                    prefixIcon: const Icon(Iconsax.health),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: InputDecoration(
                    labelText: "Allergies (Optional)",
                    prefixIcon: const Icon(Iconsax.danger),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: "Notes (Optional)",
                    prefixIcon: const Icon(Iconsax.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                
                final newChild = ChildModel(
                  name: nameController.text.trim(),
                  dob: selectedDate,
                  gender: gender,
                  specialNeeds: specialNeedsController.text.trim(),
                  allergies: allergiesController.text.trim(),
                  notes: notesController.text.trim(),
                );

                setState(() {
                  if (index != null) {
                    _children[index] = newChild;
                  } else {
                    _children.add(newChild);
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save Child"),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save changes
      if (_formKey.currentState!.validate()) {
        final double? hourlyRate = double.tryParse(_hourlyRateController.text);
        final int? years = int.tryParse(_yearsController.text);
        
        ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          hourlyRate: hourlyRate,
          yearsOfExperience: years,
          address: _addressController.text.trim(),
          profileImage: _profileImageController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          children: _children,
        );
        setState(() => _isEditing = false); // Only toggle if valid
      }
    } else {
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider); // Watch theme mode
    final user = authState.user;

    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: authState.isLoading ? null : _toggleEdit,
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               ref.read(authControllerProvider.notifier).logout();
            },
          )
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            _profileImageController.text.isNotEmpty 
                                ? _profileImageController.text 
                                : (user.profileImage ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}')
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                        if (_isEditing)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                            child: IconButton(
                              icon: _isUploadingImage 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                  : const Icon(Iconsax.camera, color: Colors.white, size: 20),
                              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Full Name",
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      validator: (value) => value!.isEmpty ? 'Name required' : null,
                    ),

                    if (!_isEditing && user.role == UserRole.sitter) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Certified Babysitter",
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    // Email (Read Only)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.sms),
                      ),
                      title: Text("Email", style: Theme.of(context).textTheme.bodySmall),
                      subtitle: Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    const Divider(height: 1),
                    
                    // Address
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Iconsax.location),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Iconsax.gps),
                          label: const Text("Use Current Location"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.location),
                        ),
                        title: Text("Address", style: Theme.of(context).textTheme.bodySmall),
                        subtitle: Text(
                          _addressController.text.isNotEmpty ? _addressController.text : "No address set",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Location Set: $_latitude, $_longitude",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Parent Specifics (Children)
                    if (user.role == UserRole.parent) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("My Children", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (_isEditing)
                            ElevatedButton.icon(
                              onPressed: () => _showChildDialog(),
                              icon: const Icon(Iconsax.add, size: 18),
                              label: const Text("Add"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_children.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Iconsax.profile_2user, size: 48, color: Theme.of(context).disabledColor),
                              const SizedBox(height: 12),
                              Text(
                                "No children profiles added yet.",
                                style: TextStyle(color: Theme.of(context).disabledColor),
                              ),
                              if (_isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: TextButton(
                                    onPressed: () => _showChildDialog(),
                                    child: const Text("Add Child Profile"),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ..._children.asMap().entries.map((entry) {
                        final index = entry.key;
                        final child = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isEditing ? () => _showChildDialog(childToEdit: child, index: index) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      child.name.isNotEmpty ? child.name[0].toUpperCase() : "?",
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          child.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(child.gender == 'Female' ? Iconsax.woman : Iconsax.man, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text("${child.gender} • ${child.age} yrs", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                        if (child.specialNeeds != null && child.specialNeeds!.isNotEmpty)
                                           Padding(
                                             padding: const EdgeInsets.only(top: 6.0),
                                             child: Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                               decoration: BoxDecoration(
                                                 color: Colors.orange.withValues(alpha: 0.1),
                                                 borderRadius: BorderRadius.circular(4),
                                               ),
                                               child: Text(
                                                 "Needs: ${child.specialNeeds}",
                                                 style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w600),
                                               ),
                                             ),
                                           ),
                                      ],
                                    ),
                                  ),
                                  if (_isEditing)
                                    IconButton(
                                      icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                                      onPressed: () => setState(() => _children.removeAt(index)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],

                    // Sitter Specifics
                    if (user.role == UserRole.sitter) ...[
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Professional Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                           Expanded(
                             child: Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Theme.of(context).cardColor,
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                                 boxShadow: [
                                   BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                 ],
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text("Hourly Rate", style: Theme.of(context).textTheme.bodySmall),
                                   const SizedBox(height: 4),
                                   _isEditing 
                                   ? TextField(
                                       controller: _hourlyRateController,
                                       keyboardType: TextInputType.number,
                                       decoration: const InputDecoration(isDense: true, prefixText: "\$"),
                                     )
                                   : Text("\$${_hourlyRateController.text}", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                 ],
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Theme.of(context).cardColor,
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                                 boxShadow: [
                                   BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                 ],
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text("Experience", style: Theme.of(context).textTheme.bodySmall),
                                   const SizedBox(height: 4),
                                   _isEditing 
                                   ? TextField(
                                       controller: _yearsController,
                                       keyboardType: TextInputType.number,
                                       decoration: const InputDecoration(isDense: true, suffixText: "years"),
                                     )
                                   : Text("${_yearsController.text} Years", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                 ],
                               ),
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Bio", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                         padding: const EdgeInsets.all(16),
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Theme.of(context).cardColor,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                         ),
                         child: _isEditing
                           ? TextField(
                               controller: _bioController,
                               maxLines: 4,
                               decoration: const InputDecoration.collapsed(hintText: "Tell parents about yourself..."),
                             )
                           : Text(
                               _bioController.text.isNotEmpty ? _bioController.text : "No bio provided.",
                               style: Theme.of(context).textTheme.bodyMedium,
                             ),
                      ),
                    ],

                    if (user.role == UserRole.sitter && _isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          "Note: Verification status cannot be edited manually.",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
