import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/tournament_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/create_match/map_location_picker_screen.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TournamentController _controller = Get.find<TournamentController>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _entryFeeController = TextEditingController();

  String? _selectedSport;
  TournamentType _tournamentType = TournamentType.singleElimination;
  DateTime? _startDate;
  DateTime? _endDate;
  MatchLocation? _selectedLocation;
  bool _isCreating = false; // Loading state

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
    _maxParticipantsController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnuva Oluştur'),
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
                    Icon(Icons.emoji_events, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Bir turnuva düzenleyin ve oyuncuları bir araya getirin!',
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

            // Tournament name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Turnuva Adı *',
                hintText: 'Örn: İstanbul Açık Tenis Turnuvası',
                prefixIcon: const Icon(Icons.emoji_events_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Turnuva adı gerekli';
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
                hintText: 'Turnuva hakkında detaylı bilgi verin...',
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
                if (value.length < 20) {
                  return 'En az 20 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sport type
            DropdownButtonFormField<String>(
              value: _selectedSport,
              decoration: InputDecoration(
                labelText: 'Spor Dalı *',
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
              validator: (value) {
                if (value == null) {
                  return 'Spor dalı seçiniz';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tournament type
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
                    'Turnuva Tipi *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RadioListTile<TournamentType>(
                    title: const Text('Eleme Usulü'),
                    subtitle: const Text('Tek maç eleme sistemi - Kaybeden elenir'),
                    value: TournamentType.singleElimination,
                    groupValue: _tournamentType,
                    onChanged: (value) => setState(() => _tournamentType = value!),
                  ),
                  Opacity(
                    opacity: 0.5,
                    child: RadioListTile<TournamentType>(
                      title: Row(
                        children: const [
                          Text('Lig Usulü'),
                          SizedBox(width: 8),
                          Icon(Icons.lock, size: 16, color: Colors.grey),
                        ],
                      ),
                      subtitle: const Text('Herkes herkesle oynar - Yakında'),
                      value: TournamentType.roundRobin,
                      groupValue: _tournamentType,
                      onChanged: null, // Disabled
                    ),
                  ),
                  Opacity(
                    opacity: 0.5,
                    child: RadioListTile<TournamentType>(
                      title: Row(
                        children: const [
                          Text('Lig Sistemi'),
                          SizedBox(width: 8),
                          Icon(Icons.lock, size: 16, color: Colors.grey),
                        ],
                      ),
                      subtitle: const Text('Grup + Playoff sistemi - Yakında'),
                      value: TournamentType.league,
                      groupValue: _tournamentType,
                      onChanged: null, // Disabled
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Şu anda sadece Eleme Usulü desteklenmektedir. Diğer formatlar yakında eklenecek!',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Start date
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Başlangıç Tarihi *'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd MMMM yyyy, HH:mm').format(_startDate!)
                    : 'Tarih seçiniz',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectStartDate(),
            ),

            const SizedBox(height: AppSpacing.md),

            // End date (optional)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              leading: const Icon(Icons.event),
              title: const Text('Bitiş Tarihi (Opsiyonel)'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd MMMM yyyy, HH:mm').format(_endDate!)
                    : 'Tarih seçiniz',
              ),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _endDate = null),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectEndDate(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Location
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              leading: const Icon(Icons.location_on),
              title: const Text('Konum *'),
              subtitle: Text(
                _selectedLocation != null
                    ? _selectedLocation!.address
                    : 'Konum seçiniz',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectLocation(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Max participants
            TextFormField(
              controller: _maxParticipantsController,
              decoration: InputDecoration(
                labelText: 'Maksimum Katılımcı Sayısı *',
                hintText: 'Örn: 16',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Katılımcı sayısı gerekli';
                }
                final num = int.tryParse(value);
                if (num == null || num < 2) {
                  return 'En az 2 katılımcı olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Entry fee
            TextFormField(
              controller: _entryFeeController,
              decoration: InputDecoration(
                labelText: 'Katılım Ücreti (TL) (Opsiyonel)',
                hintText: 'Örn: 50',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Geçerli bir tutar girin';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Create button
            ElevatedButton(
              onPressed: _isCreating ? null : _createTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Turnuva Oluştur',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _startDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      Get.snackbar('Uyarı', 'Önce başlangıç tarihini seçiniz');
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 7)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? _startDate!),
      );

      if (time != null) {
        setState(() {
          _endDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const MapLocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = MatchLocation(
          latitude: result['latitude'],
          longitude: result['longitude'],
          address: result['address'],
          city: result['city'],
          venueName: result['venueName'],
          isIndoor: result['isIndoor'] ?? false,
        );
      });
    }
  }

  Future<void> _createTournament() async {
    if (_isCreating) return; // Prevent double tap

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      Get.snackbar('Uyarı', 'Başlangıç tarihini seçiniz');
      return;
    }

    if (_selectedLocation == null) {
      Get.snackbar('Uyarı', 'Konum seçiniz');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final success = await _controller.createTournament(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sport: _selectedSport!,
        type: _tournamentType,
        startDate: _startDate!,
        endDate: _endDate,
        location: _selectedLocation!,
        maxParticipants: int.parse(_maxParticipantsController.text.trim()),
        entryFee: _entryFeeController.text.isNotEmpty
            ? double.parse(_entryFeeController.text.trim())
            : null,
      );

      if (success && mounted) {
        // Başarılı olduysa, loading'i kapat ve geri dön
        setState(() {
          _isCreating = false;
        });
        Navigator.of(context).pop(); // Go back to tournaments list
      } else {
        // Başarısız olduysa sadece loading'i kapat
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    } catch (e) {
      // Hata durumunda loading'i kapat
      debugPrint('❌ Error creating tournament: $e');
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
