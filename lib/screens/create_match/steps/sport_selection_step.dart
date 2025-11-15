import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/sport_icon.dart';

class SportSelectionStep extends StatelessWidget {
  const SportSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateMatchController>();

    return SingleChildScrollView(
      padding: AppSpacing.paddingXXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Hangi sporu oynayacaksınız?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Maç oluşturmak için önce spor dalını seçin',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Bireysel Sporlar
          Text(
            'BİREYSEL SPORLAR',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _SportCard(
                sport: SportIcon.tennis,
                icon: Icons.sports_tennis,
                color: AppColors.tennisColor,
                matchType: MatchType.individual,
                controller: controller,
              ),
              _SportCard(
                sport: SportIcon.badminton,
                icon: Icons.sports_tennis,
                color: AppColors.badmintonColor,
                matchType: MatchType.individual,
                controller: controller,
              ),
              _SportCard(
                sport: SportIcon.tableTennis,
                icon: Icons.sports_cricket,
                color: AppColors.tableTennisColor,
                matchType: MatchType.individual,
                controller: controller,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Takım Sporları
          Text(
            'TAKIM SPORLARI',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _SportCard(
                sport: SportIcon.football,
                icon: Icons.sports_soccer,
                color: AppColors.footballColor,
                matchType: MatchType.team,
                controller: controller,
              ),
              _SportCard(
                sport: SportIcon.basketball,
                icon: Icons.sports_basketball,
                color: AppColors.basketballColor,
                matchType: MatchType.team,
                controller: controller,
              ),
              _SportCard(
                sport: SportIcon.volleyball,
                icon: Icons.sports_volleyball,
                color: AppColors.volleyballColor,
                matchType: MatchType.team,
                controller: controller,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final String sport;
  final IconData icon;
  final Color color;
  final MatchType matchType;
  final CreateMatchController controller;

  const _SportCard({
    required this.sport,
    required this.icon,
    required this.color,
    required this.matchType,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedSport.value == sport;

      return InkWell(
        onTap: () => controller.selectSport(sport, matchType),
        borderRadius: AppSpacing.borderRadiusLG,
        child: Container(
          width: (MediaQuery.of(context).size.width - 80) / 2,
          height: 140,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08) // Koyu mavi açık ton
                : AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLG,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border, // Koyu mavi border
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected ? AppSpacing.shadowMD : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15) // Koyu mavi ton
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary, // Koyu mavi ikon
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Spor adı
              Text(
                sport,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary, // Koyu mavi yazı
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Maç türü badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15) // Koyu mavi ton
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  matchType == MatchType.individual ? '1v1' : 'Takım',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary, // Koyu mavi yazı
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
