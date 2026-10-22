class ResourceItem {
  final String id;
  final String title;
  final String condition;
  final int qty;
  final String city;

  final String sharedBy;
  final String sharedByEmail;
  final String sharedByUid;
  final String sharedByPhone;

  final String description;

  final String address;
  final String landmark;

  final double latitude;
  final double longitude;

  final String status;

  ResourceItem({
    required this.id,
    required this.title,
    required this.condition,
    required this.qty,
    required this.city,
    required this.sharedBy,
    required this.sharedByEmail,
    required this.sharedByUid,
    required this.sharedByPhone,
    required this.description,
    required this.address,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory ResourceItem.fromMap(
      String id, Map<String, dynamic> map) {
    return ResourceItem(
      id: id,
      title: map["title"] ?? "",
      condition: map["condition"] ?? "",
      qty: map["qty"] ?? 0,
      city: map["city"] ?? "",
      sharedBy: map["sharedBy"] ?? "",
      sharedByEmail: map["sharedByEmail"] ?? "",
      sharedByUid: map["sharedByUid"] ?? "",
      sharedByPhone: map["sharedByPhone"] ?? "",
      description: map["description"] ?? "",
      address: map["address"] ?? "",
      landmark: map["landmark"] ?? "",
      latitude: (map["latitude"] ?? 0).toDouble(),
      longitude: (map["longitude"] ?? 0).toDouble(),
      status: map["status"] ?? "Available",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "condition": condition,
      "qty": qty,
      "city": city,
      "sharedBy": sharedBy,
      "sharedByEmail": sharedByEmail,
      "sharedByUid": sharedByUid,
      "sharedByPhone": sharedByPhone,
      "description": description,
      "address": address,
      "landmark": landmark,
      "latitude": latitude,
      "longitude": longitude,
      "status": status,
    };
  }
}