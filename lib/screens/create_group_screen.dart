import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/group_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupController _controller = Get.find<GroupController>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxMembersController = TextEditingController();

  String? _selectedSport;
  GroupType _groupType = GroupType.public;
  String? _city;
  String? _district;

  final List<String> _sportOptions = [
    'Futbol',
    'Basketbol',
    'Tenis',
    'Voleybol',
    'Badminton',
    'Masa Tenisi',
    'Yüzme',
    'Koşu',
    'Diğer',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup Oluştur'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Header card
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Aynı ilgi alanlarına sahip kişileri bir araya getirin!',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Group name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Grup Adı *',
                hintText: 'Örn: İstanbul Tenis Kulübü',
                prefixIcon: const Icon(Icons.groups_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Grup adı gerekli';
                }
                if (value.length < 3) {
                  return 'En az 3 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama *',
                hintText: 'Grubunuz hakkında bilgi verin...',
                prefixIcon: const Icon(Icons.description_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama gerekli';
                }
                if (value.length < 10) {
                  return 'En az 10 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sport type
            DropdownButtonFormField<String>(
              value: _selectedSport,
              decoration: InputDecoration(
                labelText: 'Spor Dalı (Opsiyonel)',
                prefixIcon: const Icon(Icons.sports_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text('Seçiniz'),
              items: _sportOptions.map((sport) {
                return DropdownMenuItem(
                  value: sport,
                  child: Text(sport),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSport = value),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Group type
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grup Tipi *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RadioListTile<GroupType>(
                    title: const Text('Herkese Açık'),
                    subtitle: const Text('Herkes katılabilir'),
                    value: GroupType.public,
                    groupValue: _groupType,
                    onChanged: (value) => setState(() => _groupType = value!),
                  ),
                  RadioListTile<GroupType>(
                    title: const Text('Özel'),
                    subtitle: const Text('Sadece davet ile'),
                    value: GroupType.private,
                    groupValue: _groupType,
                    onChanged: (value) => setState(() => _groupType = value!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Max members
            TextFormField(
              controller: _maxMembersController,
              decoration: InputDecoration(
                labelText: 'Maksimum Üye Sayısı (Opsiyonel)',
                hintText: 'Örn: 50',
                prefixIcon: const Icon(Icons.people_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = int.tryParse(value);
                  if (number == null || number < 2) {
                    return 'En az 2 olmalı';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Etiketler (Opsiyonel)',
                hintText: 'Örn: başlangıç, hafta-sonu, sosyal',
                helperText: 'Virgül ile ayırın',
                prefixIcon: const Icon(Icons.tag_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Create button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _createGroup,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Grubu Oluştur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;

    // Parse tags
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    // Parse max members
    final maxMembers = _maxMembersController.text.isNotEmpty
        ? int.tryParse(_maxMembersController.text)
        : null;

    _controller.createGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sport: _selectedSport,
      type: _groupType,
      tags: tags,
      maxMembers: maxMembers,
      city: _city,
      district: _district,
    );
  }
}
