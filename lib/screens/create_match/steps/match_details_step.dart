import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class MatchDetailsStep extends StatelessWidget {
  const MatchDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateMatchController>();

    return SingleChildScrollView(
      padding: AppSpacing.paddingXXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maç Detayları', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxxl),

          // Tarih ve Saat
          _buildDateTimePicker(context, controller),
          const SizedBox(height: AppSpacing.xl),

          // Süre
          _buildDurationPicker(context, controller),
          const SizedBox(height: AppSpacing.xl),

          // Seviye
          _buildLevelPicker(context, controller),
          const SizedBox(height: AppSpacing.xl),

          // Mod
          _buildModePicker(context, controller),
          const SizedBox(height: AppSpacing.xl),

          // Takım başına oyuncu sayısı (sadece takım sporları için)
          Obx(() {
            if (controller.selectedMatchType.value == MatchType.team) {
              return _buildMaxPlayersPicker(context, controller);
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context, CreateMatchController controller) {
    return Obx(() {
      final dateTime = controller.selectedDateTime.value;
      return InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              controller.selectedDateTime.value = DateTime(
                date.year, date.month, date.day, time.hour, time.minute,
              );
            }
          }
        },
        child: Container(
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarih ve Saat', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      dateTime != null
                          ? DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(dateTime)
                          : 'Seçiniz',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDurationPicker(BuildContext context, CreateMatchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Süre (dakika)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => Wrap(
              spacing: AppSpacing.sm,
              children: [30, 60, 90, 120].map((duration) {
                final isSelected = controller.durationMinutes.value == duration;
                return ChoiceChip(
                  label: Text('$duration dk'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.durationMinutes.value = duration;
                  },
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildLevelPicker(BuildContext context, CreateMatchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seviye', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => Wrap(
              spacing: AppSpacing.sm,
              children: MatchLevel.values.map((level) {
                final isSelected = controller.selectedLevel.value == level;
                final labels = {
                  MatchLevel.beginner: 'Başlangıç',
                  MatchLevel.intermediate: 'Orta',
                  MatchLevel.advanced: 'İleri',
                  MatchLevel.professional: 'Profesyonel',
                };
                return ChoiceChip(
                  label: Text(labels[level]!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.selectedLevel.value = level;
                  },
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildModePicker(BuildContext context, CreateMatchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maç Tipi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => Wrap(
              spacing: AppSpacing.sm,
              children: MatchMode.values.map((mode) {
                final isSelected = controller.selectedMode.value == mode;
                final labels = {
                  MatchMode.friendly: 'Dostane',
                  MatchMode.competitive: 'Puanlı',
                };
                return ChoiceChip(
                  label: Text(labels[mode]!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.selectedMode.value = mode;
                  },
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildMaxPlayersPicker(BuildContext context, CreateMatchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Takım başına oyuncu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => Wrap(
              spacing: AppSpacing.sm,
              children: [5, 6, 7, 11].map((count) {
                final isSelected = controller.maxPlayersPerTeam.value == count;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.maxPlayersPerTeam.value = count;
                  },
                );
              }).toList(),
            )),
      ],
    );
  }
}
