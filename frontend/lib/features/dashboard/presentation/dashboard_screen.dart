import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockSitters.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final sitter = _mockSitters[index];
          return SitterCard(sitter: sitter);
        },
      ),
    );
  }
}

class SitterCard extends StatelessWidget {
  final Map<String, dynamic> sitter;

  const SitterCard({super.key, required this.sitter});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                sitter['image'],
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
                      Text(
                        sitter['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.star1, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              "${sitter['rating']}",
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
                  Text(
                    sitter['bio'],
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
                        "\$${sitter['rate']}/hr",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        "${sitter['reviews']} reviews",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
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
    );
  }
}

// Mock Data
final List<Map<String, dynamic>> _mockSitters = [
  {
    'name': 'Sarah Jenkins',
    'image': 'https://i.pravatar.cc/150?u=sarah',
    'rating': 4.9,
    'reviews': 124,
    'rate': 18,
    'bio': 'Certified babysitter with 5 years of experience. I love engaging kids with creative activities and outdoor play.',
  },
  {
    'name': 'Michael Chen',
    'image': 'https://i.pravatar.cc/150?u=michael',
    'rating': 4.8,
    'reviews': 89,
    'rate': 22,
    'bio': 'University student majoring in Early Childhood Education. Patient, reliable, and fun!',
  },
  {
    'name': 'Jessica Alverez',
    'image': 'https://i.pravatar.cc/150?u=jessica',
    'rating': 5.0,
    'reviews': 42,
    'rate': 25,
    'bio': 'Special needs certified. Experienced with toddlers and infants. CPR and First Aid trained.',
  },
  {
    'name': 'Emily Wilson',
    'image': 'https://i.pravatar.cc/150?u=emily',
    'rating': 4.7,
    'reviews': 215,
    'rate': 16,
    'bio': 'High energy and creative! I bring my own art supplies and games. Available for weekends and date nights.',
  },
  {
    'name': 'David Ross',
    'image': 'https://i.pravatar.cc/150?u=david',
    'rating': 4.9,
    'reviews': 67,
    'rate': 20,
    'bio': 'Sports enthusiast and math tutor. I can help with homework and get the kids moving outside.',
  },
];
