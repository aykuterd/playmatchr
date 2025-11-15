import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/openstreetmap_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final String? sportType; // Spor türü (opsiyonel)

  const MapLocationPickerScreen({super.key, this.sportType});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(
    41.0082,
    28.9784,
  ); // İstanbul varsayılan
  String _address = 'Konum seçiliyor...';
  String? _venueName;
  bool _isLoading = false;
  final TextEditingController _venueNameController = TextEditingController();

  // OpenStreetMap
  final OpenStreetMapService _osmService = OpenStreetMapService();
  List<SportVenue> _nearbyVenues = [];
  Set<Marker> _markers = {};
  SportVenue? _selectedVenue;
  bool _showVenueList = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    debugPrint('🗺️  Map opened with sport type: ${widget.sportType}');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _venueNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('İzin Gerekli', 'Konum izni reddedildi');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'İzin Gerekli',
          'Lütfen ayarlardan konum iznini açın',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Mevcut konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
      });

      // Haritayı konuma taşı
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition, 15),
      );

      // Adres bilgisini al
      await _getAddressFromLatLng(_selectedPosition);

      // Yakındaki spor tesislerini bul
      await _searchNearbyVenues();
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      Get.snackbar('Hata', 'Mevcut konum alınamadı: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Yakındaki spor tesislerini ara
  Future<void> _searchNearbyVenues() async {
    try {
      debugPrint('🔍 Yakındaki tesisler aranıyor...');

      final venues = await _osmService.searchNearbyVenues(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        sportType: widget.sportType,
        radius: 5.0, // 5km
      );

      setState(() {
        _nearbyVenues = venues;
        _updateMarkers();
      });

      if (venues.isNotEmpty) {
        Get.snackbar(
          '🎯 Tesisler Bulundu',
          '${venues.length} spor tesisi yakınınızda',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Tesis arama hatası: $e');
    }
  }

  /// Marker'ları güncelle
  void _updateMarkers() {
    final markers = <Marker>{};

    // Seçili konum marker'ı (yeşil)
    markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        draggable: true,
        onDragEnd: (newPosition) {
          _onMapTap(newPosition);
        },
        infoWindow: const InfoWindow(
          title: 'Seçili Konum',
          snippet: 'Manuel seçim',
        ),
      ),
    );

    // Spor tesisi marker'ları (spor türüne göre renk)
    for (int i = 0; i < _nearbyVenues.length; i++) {
      final venue = _nearbyVenues[i];
      final distance = _calculateDistance(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
        venue.latitude,
        venue.longitude,
      );
      final distanceText = _osmService.getDistanceText(distance);

      markers.add(
        Marker(
          markerId: MarkerId('venue_$i'),
          position: LatLng(venue.latitude, venue.longitude),
          icon: _getMarkerColor(venue.sport),
          onTap: () => _onVenueTap(venue),
          infoWindow: InfoWindow(
            title: venue.name,
            snippet: '${venue.sportTypeInTurkish} • $distanceText',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Spor türüne göre marker rengi
  BitmapDescriptor _getMarkerColor(String? sportType) {
    switch (sportType?.toLowerCase()) {
      case 'soccer':
      case 'football':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'basketball':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'tennis':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case 'volleyball':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'swimming':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
    }
  }

  /// Tesis marker'ına tıklandığında
  void _onVenueTap(SportVenue venue) {
    setState(() {
      _selectedVenue = venue;
      _selectedPosition = LatLng(venue.latitude, venue.longitude);
      _address = venue.name;
      _venueNameController.text = venue.name;
      _venueName = venue.name;
    });

    // Haritayı tesise odakla
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(venue.latitude, venue.longitude), 17),
    );

    debugPrint('📍 Tesis seçildi: ${venue.name}');
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          // Tesis adı olarak POI adını kullan
          if (place.name != null &&
              place.name!.isNotEmpty &&
              place.name != place.street) {
            _venueName = place.name;
            _venueNameController.text = place.name!;
          }
        });
      }
    } catch (e) {
      debugPrint('Adres alınamadı: $e');
      setState(() {
        _address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _address = 'Adres alınıyor...';
      _selectedVenue = null; // Manuel seçim yapılınca tesis seçimini kaldır
    });
    _getAddressFromLatLng(position);
    _updateMarkers(); // Marker'ları güncelle
  }

  /// Mesafe hesaplama (Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // pi / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _confirmLocation() {
    final location = MatchLocation(
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      address: _address,
      venueName: _venueNameController.text.isEmpty
          ? null
          : _venueNameController.text,
      isIndoor: false, // Kullanıcı daha sonra ayarlayacak
    );

    Get.back(result: location.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Harita
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Alt bilgi kartı
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: AppSpacing.paddingXL,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Seçili Konum',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Adres
                  Text(_address, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),

                  // Tesis adı input
                  TextField(
                    controller: _venueNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tesis Adı (Opsiyonel)',
                      hintText: 'Örn: Kadıköy Spor Salonu',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Onayla butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmLocation,
                      icon: const Icon(Icons.check),
                      label: const Text('Konumu Onayla'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
