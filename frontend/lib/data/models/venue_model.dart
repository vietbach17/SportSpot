import 'booking_model.dart';
import '../sportspot_models.dart';

class SportCategoryModel {
  final int id;
  final String name;
  final String? iconUrl;

  SportCategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory SportCategoryModel.fromJson(Map<String, dynamic> json) {
    return SportCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconUrl': iconUrl,
  };
}

class VenueItemModel {
  final int id;
  final int sportId;
  final String sportName;
  final String name;
  final String address;
  final String district;
  final double latitude;
  final double longitude;
  final String hotline;
  final String? imageUrl;
  final int basePrice;
  final int peakPrice;
  final double rating;
  final String? amenities;
  final double? distanceKm;
  final String? description;
  final List<String> galleryImages;
  final List<SubVenueModel> subVenues;
  final List<VenueServiceModel> services;

  VenueItemModel({
    required this.id,
    required this.sportId,
    required this.sportName,
    required this.name,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.hotline,
    this.imageUrl,
    required this.basePrice,
    required this.peakPrice,
    this.rating = 5.0,
    this.amenities,
    this.distanceKm,
    this.description,
    this.galleryImages = const [],
    this.subVenues = const [],
    this.services = const [],
  });

  List<String> get amenitiesList {
    if (amenities == null || amenities!.isEmpty) return [];
    return amenities!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String get distance => distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : 'Gần bạn';
  String get image => (imageUrl != null && imageUrl!.startsWith('http'))
      ? imageUrl!
      : 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800';

  factory VenueItemModel.fromJson(Map<String, dynamic> json) {
    List<String> gallery = [];
    if (json['galleryImages'] != null) {
      gallery = (json['galleryImages'] as List)
          .map((e) => e.toString())
          .toList();
    }
    if (gallery.isEmpty && json['imageUrl'] != null) {
      gallery = [json['imageUrl'].toString()];
    }

    List<SubVenueModel> subs = [];
    if (json['subVenues'] != null) {
      subs = (json['subVenues'] as List)
          .map((e) => SubVenueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<VenueServiceModel> svcs = [];
    if (json['services'] != null) {
      svcs = (json['services'] as List)
          .map((e) => VenueServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return VenueItemModel(
      id: json['id'] ?? 0,
      sportId: json['sportId'] ?? 1,
      sportName: json['sportName'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      hotline: json['hotline'] ?? '',
      imageUrl: json['imageUrl'],
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      peakPrice: (json['peakPrice'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      amenities: json['amenities'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      description: json['description'],
      galleryImages: gallery,
      subVenues: subs,
      services: svcs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sportId': sportId,
    'sportName': sportName,
    'name': name,
    'address': address,
    'district': district,
    'latitude': latitude,
    'longitude': longitude,
    'hotline': hotline,
    'imageUrl': imageUrl,
    'basePrice': basePrice,
    'peakPrice': peakPrice,
    'rating': rating,
    'amenities': amenities,
    'distanceKm': distanceKm,
    'description': description,
    'galleryImages': galleryImages,
    'subVenues': subVenues.map((s) => s.toJson()).toList(),
    'services': services.map((s) => s.toJson()).toList(),
  };
}

extension VenueItemModelToSportSpotVenue on VenueItemModel {
  SportSpotVenue toSportSpotVenue() {
    return SportSpotVenue(
      id: id.toString(),
      name: name,
      address: '$address, $district',
      distance: distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : 'Gần bạn',
      rating: rating,
      reviewCount: 120,
      priceFrom: basePrice,
      openUntil: '23:00',
      totalCourts: subVenues.isNotEmpty ? subVenues.length : 6,
      isVerified: true,
      image: (imageUrl != null && imageUrl!.startsWith('http'))
          ? imageUrl!
          : 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      disciplines: [sportName],
      amenities: const [
        VenueAmenity(label: 'Bãi xe', icon: 'local_parking'),
        VenueAmenity(label: 'Căn tin', icon: 'local_cafe'),
      ],
      slotsAvailableToday: 8,
      courts: subVenues.map((s) => CourtInfo(
        id: s.id.toString(),
        name: s.name,
        surface: 'Maple Wood',
        type: 'Indoor Pro',
        tag: 'BWF Certified',
      )).toList(),
    );
  }
}

