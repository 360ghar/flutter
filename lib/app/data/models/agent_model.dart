class AgentModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String image;
  final double rating;
  final String experience;
  final String specialization;

  AgentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.image,
    required this.rating,
    required this.experience,
    required this.specialization,
  });

  AgentModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? image,
    double? rating,
    String? experience,
    String? specialization,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      specialization: specialization ?? this.specialization,
    );
  }
} 