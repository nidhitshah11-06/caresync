class Patient {
  final String id;
  final String name;
  final String phone;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  // Create from JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
    );
  }
}