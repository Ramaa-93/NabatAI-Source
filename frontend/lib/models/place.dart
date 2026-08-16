class Place {
  final int id;
  final String name;
  final String arabicName;
  final String city;
  final String category;
  final String description;
  final bool supportsReconstruction;
  final List<String> nearbyPlaces;

  Place({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.city,
    required this.category,
    required this.description,
    required this.supportsReconstruction,
    required this.nearbyPlaces,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? 0,
      name: json['name_en'] ?? json['name'] ?? '',
      arabicName: json['name_ar'] ?? json['arabic_name'] ?? '',
      city: json['city'] ?? '',
      category: json['category'] ?? '',
      description:
          json['short_description'] ?? json['description'] ?? '',
      supportsReconstruction:
          json['supports_reconstruction'] ?? false,
      nearbyPlaces: json['nearby_places'] is List
          ? List<String>.from(
              json['nearby_places'].map(
                (item) => item.toString(),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': name,
      'name_ar': arabicName,
      'city': city,
      'category': category,
      'short_description': description,
      'supports_reconstruction': supportsReconstruction,
      'nearby_places': nearbyPlaces,
    };
  }
}