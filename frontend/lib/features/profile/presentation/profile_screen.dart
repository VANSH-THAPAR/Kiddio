import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart'; // Add Geolocator
import 'package:image_picker/image_picker.dart'; // Add Image Picker
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme.dart';
import '../../auth/models/user_model.dart';
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

      // Upload to Firebase Storage
      final user = ref.read(authControllerProvider).user;
      if (user == null) return;

      final file = File(pickedFile.path);
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

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
        );
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: _isUploadingImage 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                                  : const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value!.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email (Read Only)
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.my_location),
                          label: const Text("Update Location from GPS"),
                        ),
                      ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Location Set: $_latitude, $_longitude",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Sitter Specifics
                    if (user.role == UserRole.sitter) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text("Sitter Details", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                           Expanded(
                             child: TextFormField(
                               controller: _hourlyRateController,
                               enabled: _isEditing,
                               keyboardType: TextInputType.number,
                               decoration: const InputDecoration(
                                 labelText: 'Rate (\$/hr)',
                                 border: OutlineInputBorder(),
                                 prefixIcon: Icon(Icons.attach_money),
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: TextFormField(
                               controller: _yearsController,
                               enabled: _isEditing,
                               keyboardType: TextInputType.number,
                               decoration: const InputDecoration(
                                 labelText: 'Years Exp.',
                                 border: OutlineInputBorder(),
                                 prefixIcon: Icon(Icons.history),
                               ),
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                         controller: _bioController,
                         enabled: _isEditing,
                         maxLines: 4,
                         decoration: const InputDecoration(
                           labelText: 'Bio',
                           border: OutlineInputBorder(),
                           alignLabelWithHint: true,
                         ),
                      ),
                    ],

                    if (user.role == UserRole.sitter && _isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          "Note: Verification status cannot be edited manually.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
