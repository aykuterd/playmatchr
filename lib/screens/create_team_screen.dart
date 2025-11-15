import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/profile_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/sport_icon.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedSport;
  bool _isCreating = false;

  final List<String> _sports = [
    SportIcon.football,
    SportIcon.basketball,
    SportIcon.volleyball,
    SportIcon.tennis,
    SportIcon.badminton,
    SportIcon.tableTennis,
  ];

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate() || _selectedSport == null) {
      Get.snackbar('Hata', 'Lütfen tüm gerekli alanları doldurun');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        Get.snackbar('Hata', 'Kullanıcı bulunamadı');
        return;
      }

      final team = Team(
        id: '',
        name: _nameController.text.trim(),
        sport: _selectedSport!,
        slogan: _sloganController.text.trim().isEmpty
            ? null
            : _sloganController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        adminId: currentUserId,
        memberIds: [currentUserId], // Admin otomatik üye
        createdAt: DateTime.now(),
      );

      await _firestoreService.createTeam(team);

      // Profil controller'ı güncelle
      final profileController = Get.find<ProfileController>();
      await profileController.loadTeams();

      Get.back();
      Get.snackbar('Başarılı', 'Takım oluşturuldu!');
    } catch (e) {
      debugPrint('Create team error: $e');
      Get.snackbar('Hata', 'Takım oluşturulamadı');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Oluştur'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXXL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Takım Adı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Takım Adı *',
                  hintText: 'Örn: Kadıköy Yıldızları',
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Takım adı gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Spor Seçimi
              Text(
                'Spor Dalı *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _sports.map((sport) {
                  final isSelected = _selectedSport == sport;
                  return ChoiceChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSport = selected ? sport : null;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Slogan
              TextFormField(
                controller: _sloganController,
                decoration: const InputDecoration(
                  labelText: 'Slogan (Opsiyonel)',
                  hintText: 'Örn: Birlikte Kazanırız!',
                  prefixIcon: Icon(Icons.format_quote),
                ),
                maxLength: 50,
              ),

              const SizedBox(height: AppSpacing.md),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Takımınızı tanıtın...',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 200,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Oluştur butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createTeam,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isCreating ? 'Oluşturuluyor...' : 'Takımı Oluştur'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Not
              Text(
                '* Takım oluşturduktan sonra arkadaşlarınızı takıma ekleyebilirsiniz.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sloganController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
