import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/create_match/map_location_picker_screen.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class LocationSelectionStep extends StatelessWidget {
  const LocationSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateMatchController>();

    return SingleChildScrollView(
      padding: AppSpacing.paddingXXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Konum Seçimi', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Maç oynayacağınız yeri haritadan seçin',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Harita ekranını aç
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Get.to(
                () => MapLocationPickerScreen(
                  sportType: controller.selectedSport.value,
                ),
              );
              if (result != null && result is Map<String, dynamic>) {
                // Map'ten MatchLocation oluştur ve İndoor durumunu koru
                final locationData = MatchLocation.fromMap(result);
                controller.selectedLocation.value = MatchLocation(
                  latitude: locationData.latitude,
                  longitude: locationData.longitude,
                  address: locationData.address,
                  city: locationData.city,
                  venueName: locationData.venueName,
                  isIndoor: controller.isIndoor.value,
                );
                Get.snackbar('Başarılı', 'Konum seçildi');
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('Haritadan Konum Seç'),
          ),

          const SizedBox(height: AppSpacing.xl),

          // İç/Dış mekan
          Obx(() => SwitchListTile(
                title: const Text('Kapalı Alan'),
                subtitle: const Text('Açık alan maçlar için kapalı'),
                value: controller.isIndoor.value,
                onChanged: (value) => controller.isIndoor.value = value,
              )),

          // Seçilen konum gösterimi
          Obx(() {
            final location = controller.selectedLocation.value;
            if (location != null) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(location.venueName ?? 'Konum'),
                  subtitle: Text(location.address),
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }
}
