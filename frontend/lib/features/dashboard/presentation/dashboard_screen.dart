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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch nearbySittersProvider instead of sittersProvider
    // nearbySittersProvider returns AsyncValue<List<UserModel>> so we can try unwrapping it here for better DX if needed, 
    // but ref.watch(nearbySittersProvider) already gives us the AsyncValue.
    
    // Wait, my definition of nearbySittersProvider was Provider<AsyncValue<...>>
    // so watching it returns AsyncValue<...>. Correct.
    final sittersAsyncValue = ref.watch(nearbySittersProvider);
    final currentUser = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find a Sitter',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.search_normal),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.filter),
          ),
        ],
      ),
      body: sittersAsyncValue.when(
        data: (sitters) {
          if (sitters.isEmpty) {
            return const Center(child: Text("No sitters found yet."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sitters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sitter = sitters[index];
              return SitterCard(sitter: sitter, currentUser: currentUser);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class SitterCard extends StatelessWidget {
  final UserModel sitter;
  final UserModel? currentUser;

  const SitterCard({super.key, required this.sitter, this.currentUser});

  String _getDistanceText() {
    if (currentUser?.latitude == null || currentUser?.longitude == null) {
      return "Set your location to see distance";
    }
    if (sitter.latitude == null || sitter.longitude == null) {
      return "Location not provided by sitter";
    }
    
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

  @override
  Widget build(BuildContext context) {
    final distanceText = _getDistanceText();

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                    color: Colors.grey[200],
                    child: const Icon(Iconsax.user),
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
                      children: [
                        Expanded(
                          child: Text(
                            sitter.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (sitter.rating != null && sitter.rating! > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.star1, size: 14, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "${sitter.rating!.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (distanceText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                distanceText,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sitter.bio != null) 
                      Text(
                        sitter.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sitter.hourlyRate != null 
                              ? "\$${sitter.hourlyRate!.toStringAsFixed(0)}/hr"
                              : "Rate Negotiable",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (sitter.reviewCount != null && sitter.reviewCount! > 0)
                          Expanded(
                            child: Text(
                              "${sitter.reviewCount} reviews",
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
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
