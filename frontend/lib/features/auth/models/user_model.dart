enum UserRole { parent, sitter }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String profileImage;
  final UserRole role;
  
  // Sitter specific fields (nullable for parents)
  final String? bio;
  final double? hourlyRate;
  final double? rating;
  final int? reviewCount;
  final List<String>? certifications; // e.g., ["CPR", "First Aid"]
  final List<String>? skills; // e.g., ["Toddlers", "Homework Help"]

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.profileImage,
    required this.role,
    this.bio,
    this.hourlyRate,
    this.rating,
    this.reviewCount,
    this.certifications,
    this.skills,
  });

  // Factory constructor for creating a new UserModel from a map (e.g. from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profileImage: map['profileImage'] ?? '',
      role: map['role'] == 'sitter' ? UserRole.sitter : UserRole.parent,
      bio: map['bio'],
      hourlyRate: map['hourlyRate']?.toDouble(),
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
      certifications: map['certifications'] != null 
          ? List<String>.from(map['certifications'])
          : null,
      skills: map['skills'] != null 
          ? List<String>.from(map['skills'])
          : null,
    );
  }

  // Method for converting a UserModel instance to a map (e.g. for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'profileImage': profileImage,
      'role': role == UserRole.sitter ? 'sitter' : 'parent',
      if (bio != null) 'bio': bio,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (certifications != null) 'certifications': certifications,
      if (skills != null) 'skills': skills,
    };
  }
}
