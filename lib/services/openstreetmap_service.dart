import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SportVenue {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? sport;
  final String? surface;
  final String? access;
  final String? description;
  final Map<String, dynamic>? tags;

  SportVenue({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.sport,
    this.surface,
    this.access,
    this.description,
    this.tags,
  });

  factory SportVenue.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>?;

    // İsim öncelik sırası: name > name:tr > sport türü
    String name =
        tags?['name'] ?? tags?['name:tr'] ?? tags?['sport'] ?? 'Spor Tesisi';

    return SportVenue(
      id: json['id'].toString(),
      name: name,
      latitude: json['lat'] ?? json['center']?['lat'] ?? 0.0,
      longitude: json['lon'] ?? json['center']?['lon'] ?? 0.0,
      sport: tags?['sport'],
      surface: tags?['surface'],
      access: tags?['access'],
      description: tags?['description'],
      tags: tags,
    );
  }

  String get sportTypeInTurkish {
    switch (sport?.toLowerCase()) {
      case 'soccer':
      case 'football':
        return 'Futbol';
      case 'basketball':
        return 'Basketbol';
      case 'tennis':
        return 'Tenis';
      case 'volleyball':
        return 'Voleybol';
      case 'swimming':
        return 'Yüzme';
      case 'badminton':
        return 'Badminton';
      case 'table_tennis':
        return 'Masa Tenisi';
      case 'athletics':
        return 'Atletizm';
      case 'fitness':
        return 'Fitness';
      default:
        return sport ?? 'Spor Tesisi';
    }
  }

  String get surfaceTypeInTurkish {
    switch (surface?.toLowerCase()) {
      case 'grass':
        return 'Çim';
      case 'artificial_turf':
      case 'artificial':
        return 'Suni Çim';
      case 'asphalt':
        return 'Asfalt';
      case 'concrete':
        return 'Beton';
      case 'tartan':
        return 'Tartan';
      case 'wood':
        return 'Ahşap';
      case 'clay':
        return 'Toprak';
      default:
        return surface ?? 'Bilinmiyor';
    }
  }

  bool get isPublic {
    return access == null ||
        access == 'yes' ||
        access == 'public' ||
        access == 'permissive';
  }
}

class OpenStreetMapService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Overpass QL sorgusu oluştur
  String _buildQuery({
    required double latitude,
    required double longitude,
    required double radius, // km cinsinden
    String? sportType,
  }) {
    // Koordinatları bbox'a çevir (yaklaşık)
    final latDelta = radius / 111.0; // 1 derece ≈ 111km
    final lonDelta =
        radius / (111.0 * cos(latitude * 0.0174533)); // cos(lat in radians)

    final south = latitude - latDelta;
    final north = latitude + latDelta;
    final west = longitude - lonDelta;
    final east = longitude + lonDelta;

    // Spor türüne göre filtre
    String sportFilter = '';
    if (sportType != null) {
      final osmSportType = _getSportTagValue(sportType);
      if (osmSportType != null) {
        sportFilter = '[sport~"$osmSportType"]';
      }
    }

    // Overpass QL sorgusu
    return '''
    [out:json][timeout:25];
    (
      node["leisure"="pitch"]$sportFilter($south,$west,$north,$east);
      way["leisure"="pitch"]$sportFilter($south,$west,$north,$east);
      node["leisure"="sports_centre"]($south,$west,$north,$east);
      way["leisure"="sports_centre"]($south,$west,$north,$east);
      node["amenity"="swimming_pool"]($south,$west,$north,$east);
      way["amenity"="swimming_pool"]($south,$west,$north,$east);
    );
    out body;
    >;
    out skel qt;
    ''';
  }

  /// Spor türü için OSM tag değeri
  String? _getSportTagValue(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'futbol':
        return 'soccer|football';
      case 'basketbol':
        return 'basketball';
      case 'tenis':
        return 'tennis';
      case 'voleybol':
        return 'volleyball';
      case 'yüzme':
        return 'swimming';
      case 'badminton':
        return 'badminton';
      case 'masa tenisi':
        return 'table_tennis';
      default:
        return null; // Tüm sporlar
    }
  }

  /// Yakındaki spor tesislerini bul
  Future<List<SportVenue>> searchNearbyVenues({
    required double latitude,
    required double longitude,
    String? sportType,
    double radius = 5.0, // 5km varsayılan
  }) async {
    try {
      final query = _buildQuery(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        sportType: sportType,
      );

      debugPrint('🗺️  OpenStreetMap sorgusu başlıyor...');
      debugPrint('📍 Konum: ($latitude, $longitude)');
      debugPrint('🎯 Spor türü: ${sportType ?? "Tümü"}');
      debugPrint('📏 Yarıçap: ${radius}km');

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        // Node ve way'leri parse et
        final venues = <SportVenue>[];
        final nodes =
            <String, Map<String, dynamic>>{}; // way'ler için node koordinatları

        // Önce tüm node'ları topla
        for (var element in elements) {
          if (element['type'] == 'node') {
            nodes[element['id'].toString()] = element;

            // Eğer tag'leri varsa (spor tesisi), listeye ekle
            if (element['tags'] != null) {
              venues.add(SportVenue.fromJson(element));
            }
          }
        }

        // Sonra way'leri işle
        for (var element in elements) {
          if (element['type'] == 'way' && element['tags'] != null) {
            // Way'in merkez koordinatını hesapla
            final nodeRefs = element['nodes'] as List?;
            if (nodeRefs != null && nodeRefs.isNotEmpty) {
              double? centerLat;
              double? centerLon;

              // İlk node'un koordinatlarını al
              final firstNodeId = nodeRefs[0].toString();
              if (nodes.containsKey(firstNodeId)) {
                centerLat = nodes[firstNodeId]!['lat'];
                centerLon = nodes[firstNodeId]!['lon'];
              }

              if (centerLat != null && centerLon != null) {
                final wayData = Map<String, dynamic>.from(element);
                wayData['lat'] = centerLat;
                wayData['lon'] = centerLon;
                venues.add(SportVenue.fromJson(wayData));
              }
            }
          }
        }

        // Mesafeye göre sırala
        venues.sort((a, b) {
          final distA = _calculateDistance(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          );
          final distB = _calculateDistance(
            latitude,
            longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });

        debugPrint('✅ ${venues.length} spor tesisi bulundu!');

        // İlk 5 tesisi logla
        for (var i = 0; i < venues.length && i < 5; i++) {
          final venue = venues[i];
          final distance = _calculateDistance(
            latitude,
            longitude,
            venue.latitude,
            venue.longitude,
          );
          debugPrint(
            '   ${i + 1}. ${venue.name} - ${venue.sportTypeInTurkish} (${distance.toStringAsFixed(1)}km)',
          );
        }

        return venues;
      } else {
        debugPrint('❌ HTTP Hatası: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OpenStreetMap sorgu hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// İki nokta arası mesafe hesaplama (Haversine formula) - km cinsinden
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos(((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))) / 2;

    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Mesafe metni oluştur
  String getDistanceText(double km) {
    if (km < 1) {
      return '${(km * 1000).round()}m';
    } else {
      return '${km.toStringAsFixed(1)}km';
    }
  }
}
