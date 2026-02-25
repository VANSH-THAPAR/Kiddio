import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import '../../../core/theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_controller.dart'; // Import Auth Controller
import '../providers/sitter_provider.dart';
import 'sitter_details_screen.dart'; // Import SitterDetailsScreen

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  RangeValues _priceRange = const RangeValues(10, 100);
  double _minRating = 0;
  bool _verifiedOnly = false;
  int _yearsExperience = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Options',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _priceRange = const RangeValues(10, 100);
                            _minRating = 0;
                            _verifiedOnly = false;
                            _yearsExperience = 0;
                          });
                          setStateSheet(() {
                             _priceRange = const RangeValues(10, 100);
                             _minRating = 0;
                             _verifiedOnly = false;
                             _yearsExperience = 0;
                          });
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Price Range
                  Text(
                    'Hourly Rate',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${_priceRange.start.round()}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      Text('\$${_priceRange.end.round()}+', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 10,
                    max: 100,
                    divisions: 18,
                    activeColor: AppTheme.primaryColor,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setStateSheet(() => _priceRange = values);
                      setState(() {});
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Minimum Rating
                  Text(
                    'Minimum Rating',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_minRating > 0 ? '${_minRating.toStringAsFixed(1)} Stars' : 'Any', 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: AppTheme.primaryColor)),
                    ],
                  ),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    activeColor: Colors.amber,
                    label: _minRating.toString(),
                    onChanged: (value) {
                      setStateSheet(() => _minRating = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // Years of Experience
                  Text(
                    'Experience',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('$_yearsExperience+ Years', 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: AppTheme.primaryColor)),
                    ],
                  ),
                  Slider(
                    value: _yearsExperience.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: AppTheme.primaryColor,
                    label: "$_yearsExperience",
                    onChanged: (value) {
                      setStateSheet(() => _yearsExperience = value.toInt());
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // Verified Only
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Verified Sitters Only',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Show only sitters with verified background checks',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),
                    value: _verifiedOnly,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setStateSheet(() => _verifiedOnly = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch nearbySittersProvider instead of sittersProvider
    // nearbySittersProvider returns AsyncValue<List<UserModel>>
    final sittersAsyncValue = ref.watch(nearbySittersProvider);
    final currentUser = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Filter Logic
    List<UserModel> filteredSitters = [];
    
    sittersAsyncValue.whenData((sitters) {
      filteredSitters = sitters.where((sitter) {
        // Search Query (Name)
        final query = _searchController.text.toLowerCase();
        final matchesName = parserName(sitter.name).contains(query);
        if (!matchesName) return false;

        // Price Filter
        final rate = sitter.hourlyRate ?? 0;
        // If rate is negotiable (null or 0), maybe show it? or let's assume 0 is free?
        // Let's assume if rate is null, it passes if range starts at min.
        if (rate < _priceRange.start || rate > _priceRange.end) {
           if (sitter.hourlyRate != null) return false; 
        }

        // Rating Filter
        final rating = sitter.rating ?? 0;
        if (rating < _minRating) return false;

        // Experience Filter
        final exp = sitter.yearsOfExperience ?? 0;
        if (exp < _yearsExperience) return false;

        // Verified Filter
        if (_verifiedOnly && !sitter.isVerified) return false;

        return true;
      }).toList();
    });

    final hasActiveFilters = _minRating > 0 || _verifiedOnly || _yearsExperience > 0 || _priceRange.start > 10 || _priceRange.end < 100;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Find a Sitter',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name...',
                            prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterModal,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: hasActiveFilters ? AppTheme.primaryColor : (isDark ? Colors.grey[900] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Iconsax.setting_4, 
                              color: hasActiveFilters ? Colors.white : (isDark ? Colors.white : Colors.black)
                            ),
                            if (hasActiveFilters)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Quick Filters (Chips)
                if (sittersAsyncValue.hasValue)
                   Padding(
                     padding: const EdgeInsets.only(top: 12.0),
                     child: SizedBox(
                       height: 32,
                       child: ListView(
                         scrollDirection: Axis.horizontal,
                         children: [
                           _buildFilterChip("Verified", _verifiedOnly, () => setState(() => _verifiedOnly = !_verifiedOnly)),
                           const SizedBox(width: 8),
                           _buildFilterChip("4+ Stars", _minRating >= 4, () {
                             setState(() => _minRating = _minRating == 4 ? 0 : 4);
                           }),
                           const SizedBox(width: 8),
                           _buildFilterChip("Experienced (>2yr)", _yearsExperience >= 2, () {
                             setState(() => _yearsExperience = _yearsExperience == 2 ? 0 : 2);
                           }),
                         ],
                       ),
                     ),
                   ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: sittersAsyncValue.when(
              data: (sitters) {
                if (filteredSitters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Iconsax.search_status, size: 48, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No sitters found",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Try adjusting your filters",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _priceRange = const RangeValues(10, 100);
                              _minRating = 0;
                              _verifiedOnly = false;
                              _yearsExperience = 0;
                            });
                          },
                          child: const Text("Clear All Filters"),
                        )
                      ],
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Icon(Iconsax.location, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            "Sorted by nearest location",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredSitters.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final sitter = filteredSitters[index];
                          return SitterCard(sitter: sitter, currentUser: currentUser);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : (isDark ? Colors.grey[800] : Colors.white),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  String parserName(String name) {
    return name.toLowerCase();
  }
}

class SitterCard extends StatelessWidget {
  final UserModel sitter;
  final UserModel? currentUser;

  const SitterCard({super.key, required this.sitter, this.currentUser});

  String _getDistanceText() {
    if (currentUser?.latitude != null && currentUser?.longitude != null && sitter.latitude != null && sitter.longitude != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        currentUser!.latitude!,
        currentUser!.longitude!,
        sitter.latitude!,
        sitter.longitude!,
      );
      
      if (distanceInMeters < 1000) {
        return "${distanceInMeters.toStringAsFixed(0)} m away";
      } else {
        return "${(distanceInMeters / 1000).toStringAsFixed(1)} km away";
      }
    }
    
    // Fallback if no location data available for calculation
    if (sitter.address != null && sitter.address!.isNotEmpty) {
      return sitter.address!;
    }
    
    return "Location unavailable";
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = _getDistanceText();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SitterDetailsScreen(sitter: sitter),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), // Replaces Card margin
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16), // Match profile style
                child: Image.network(
                  (sitter.profileImage?.isNotEmpty ?? false)
                      ? sitter.profileImage!
                      : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(sitter.name)}&background=random',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    child: Icon(Iconsax.user, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sitter.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              if (sitter.isVerified)
                                Row(
                                  children: [
                                    Icon(Iconsax.verify5, size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Verified",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (sitter.rating != null && sitter.rating! > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.star1, size: 14, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "${sitter.rating!.toStringAsFixed(1)}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Location / Bio
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (sitter.bio != null && sitter.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sitter.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    
                    // Footer: Rate & Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sitter.hourlyRate != null 
                                ? "\$${sitter.hourlyRate!.toStringAsFixed(0)}/hr"
                                : "Rate Negotiable",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (sitter.reviewCount != null && sitter.reviewCount! > 0)
                          Row(
                            children: [
                              Text(
                                "${sitter.reviewCount} reviews",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Iconsax.arrow_right_3, size: 14, color: Colors.grey[400]),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// removed mock data
