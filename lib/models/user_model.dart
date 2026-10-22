class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String role; // sender / receiver

  // 🔥 NEW FIELDS
  final String address;
  final String landmark;
  final double latitude;
  final double longitude;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.role,
    this.address = "",
    this.landmark = "",
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      city: map["city"] ?? "",
      role: map["role"] ?? "receiver",
      address: map["address"] ?? "",
      landmark: map["landmark"] ?? "",
      latitude: (map["latitude"] ?? 0).toDouble(),
      longitude: (map["longitude"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "city": city,
      "role": role,
      "address": address,
      "landmark": landmark,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}