class Plot {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String status; // 'available' | 'booked'
  final String? imageUrl;
  final double? price;
  final String? googleMapsLink;
  final DateTime createdAt;

  Plot({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.status = 'available',
    this.imageUrl,
    this.price,
    this.googleMapsLink,
    required this.createdAt,
  });

  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      address: map['address'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      status: map['status'] ?? 'available',
      imageUrl: map['image_url'],
      price: map['price']?.toDouble(),
      googleMapsLink: map['google_maps_link'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'image_url': imageUrl,
      'price': price,
      'google_maps_link': googleMapsLink,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
