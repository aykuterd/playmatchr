import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/profile_setup_controller.dart';
import 'package:playmatchr/constants/turkey_cities.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileSetupController controller = Get.put(ProfileSetupController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const DefaultTextStyle(
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
          child: Text('Profilini Tamamla'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontFamily: 'Roboto',
                ),
                child: Text('Hoş Geldin!'),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                ),
                child: const Text(
                  'Profilini tamamlayarak başla',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Profile Photo Section
              Obx(() {
                final hasExisting = controller.existingPhotoUrl.value != null;
                final hasSelected = controller.selectedImagePath.value != null;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: controller.pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(
                                color: const Color(0xFF1E3A8A),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: hasSelected
                                  ? Image.file(
                                      File(controller.selectedImagePath.value!),
                                      fit: BoxFit.cover,
                                    )
                                  : hasExisting
                                      ? Image.network(
                                          controller.existingPhotoUrl.value!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey[400],
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!hasSelected && !hasExisting)
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                        child: const Text('Profil fotoğrafı ekle (opsiyonel)'),
                      ),
                    if (hasExisting && !hasSelected)
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                        child: const Text('Google fotoğrafın kullanılacak'),
                      ),
                  ],
                );
              }),

              const SizedBox(height: 30),

              // Cover Photo Section
              Obx(() {
                final hasCoverExisting = controller.existingCoverPhotoUrl.value != null;
                final hasCoverSelected = controller.selectedCoverImagePath.value != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'Roboto',
                      ),
                      child: Text('Kapak Fotoğrafı (Opsiyonel)'),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: controller.pickCoverImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              if (hasCoverSelected)
                                Image.file(
                                  File(controller.selectedCoverImagePath.value!),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              else if (hasCoverExisting)
                                Image.network(
                                  controller.existingCoverPhotoUrl.value!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Kapak fotoğrafı ekle',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Kapak fotoğrafı ekle',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Camera icon overlay
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 30),

              // Username Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(
                  () => TextField(
                    controller: controller.usernameController,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      hintText: 'Kullanıcı adını gir',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF1E3A8A),
                      ),
                      errorText: controller.usernameError.value,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bio Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.bioController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    labelText: 'Hakkında (Opsiyonel)',
                    hintText: 'Kendinden bahset...',
                    prefixIcon: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF1E3A8A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // City Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedCity.value.isEmpty
                          ? null
                          : controller.selectedCity.value,
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        hintText: 'Şehir seçin',
                        helperText: 'Sana yakın sporcular bulabilmemiz için gerekli',
                        helperMaxLines: 2,
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: Color(0xFF1E3A8A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(20),
                      ),
                      items: TurkeyCities.cityNames.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        controller.selectedCity.value = value ?? '';
                        controller.selectedDistrict.value = ''; // Reset district
                      },
                      isExpanded: true,
                    )),
              ),

              const SizedBox(height: 16),

              // District Dropdown (only show if city is selected)
              Obx(() {
                if (controller.selectedCity.value.isEmpty) {
                  return const SizedBox.shrink();
                }

                final districts = TurkeyCities.getDistricts(controller.selectedCity.value);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedDistrict.value.isEmpty
                        ? null
                        : controller.selectedDistrict.value,
                    decoration: const InputDecoration(
                      labelText: 'İlçe',
                      hintText: 'İlçe seçin',
                      helperText: 'Sana yakın sporcular bulabilmemiz için gerekli',
                      helperMaxLines: 2,
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: Color(0xFF1E3A8A),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(20),
                    ),
                    items: [
                      ...districts.map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      controller.selectedDistrict.value = value ?? '';
                    },
                    isExpanded: true,
                  ),
                );
              }),

              const SizedBox(height: 30),

              // Favorite Sports Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      fontFamily: 'Roboto',
                    ),
                    child: Text('Favori Sporların'),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: controller.availableSports.map((sport) {
                        final isSelected = controller.selectedSports.contains(sport);
                        return ChoiceChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            controller.toggleSport(sport);
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: const Color(0xFF1E3A8A),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          pressElevation: 5,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                            ),
                            child: Text('Devam Et'),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
