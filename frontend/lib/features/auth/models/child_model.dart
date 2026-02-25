class ChildModel {
  final String name;
  final DateTime dob; // Date of Birth
  final String gender;
  final String? specialNeeds;
  final String? allergies;
  final String? notes;

  ChildModel({
    required this.name,
    required this.dob,
    required this.gender,
    this.specialNeeds,
    this.allergies,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'specialNeeds': specialNeeds,
      'allergies': allergies,
      'notes': notes,
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      name: map['name'] ?? '',
      dob: DateTime.parse(map['dob']),
      gender: map['gender'] ?? '',
      specialNeeds: map['specialNeeds'],
      allergies: map['allergies'],
      notes: map['notes'],
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
