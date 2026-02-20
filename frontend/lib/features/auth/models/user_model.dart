enum UserRole { parent, sitter }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profileImage;
  final UserRole role;

  // Sitter specific fields (nullable for parents)
  final String? bio;
  final double? hourlyRate;
  final double? rating;
  final int? reviewCount;
  final int? yearsOfExperience;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String>? certifications; // e.g., ["CPR", "First Aid"]
  final List<String>? skills; // e.g., ["Toddlers", "Homework Help"]

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profileImage,
    required this.role,
    this.bio,
    this.hourlyRate,
    this.rating,
    this.reviewCount,
    this.yearsOfExperience,
    this.isVerified = false,
    this.latitude,
    this.longitude,
    this.address,
    this.certifications,
    this.skills,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profileImage,
    UserRole? role,
    String? bio,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    int? yearsOfExperience,
    bool? isVerified,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? certifications,
    List<String>? skills,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      isVerified: isVerified ?? this.isVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      certifications: certifications ?? this.certifications,
      skills: skills ?? this.skills,
    );
  }

  // Factory constructor for creating a new UserModel from a map (e.g. from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profileImage: map['profileImage'],
      role: map['role'] == 'sitter' ? UserRole.sitter : UserRole.parent,
      bio: map['bio'],
      hourlyRate: map['hourlyRate']?.toDouble(),
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount']?.toInt(),
      yearsOfExperience: map['yearsOfExperience']?.toInt(),
      isVerified: map['isVerified'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      certifications: map['certifications'] != null
          ? List<String>.from(map['certifications'])
          : null,
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
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
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'isVerified': isVerified,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (certifications != null) 'certifications': certifications,
      if (skills != null) 'skills': skills,
    };
  }
}
