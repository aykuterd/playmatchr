import 'package:flutter/material.dart';
import 'package:playmatchr/theme/app_colors.dart';

/// Spor türlerine göre özel ikonlar ve renkler
class SportIcon {
  // Spor isimleri - tutarlılık için
  static const String tennis = 'Tenis';
  static const String football = 'Futbol';
  static const String basketball = 'Basketbol';
  static const String volleyball = 'Voleybol';
  static const String badminton = 'Badminton';
  static const String tableTennis = 'Masa Tenisi';

  // Spor türlerine göre renkler
  static Color getColorForSport(String sport) {
    switch (sport) {
      case tennis:
        return AppColors.tennisColor;
      case football:
        return AppColors.footballColor;
      case basketball:
        return AppColors.basketballColor;
      case volleyball:
        return AppColors.volleyballColor;
      case badminton:
        return AppColors.badmintonColor;
      case tableTennis:
        return AppColors.tableTennisColor;
      default:
        return AppColors.primary;
    }
  }

  // Spor türlerine göre ikonlar
  static IconData getIconForSport(String sport) {
    switch (sport) {
      case tennis:
        return Icons.sports_tennis;
      case football:
        return Icons.sports_soccer;
      case basketball:
        return Icons.sports_basketball;
      case volleyball:
        return Icons.sports_volleyball;
      case badminton:
        return Icons.sports_tennis; // Badminton için alternatif
      case tableTennis:
        return Icons.sports_cricket; // Masa tenisi için alternatif
      default:
        return Icons.sports;
    }
  }

  // Tüm sporlar listesi
  static List<String> getAllSports() {
    return [
      tennis,
      football,
      basketball,
      volleyball,
      badminton,
      tableTennis,
    ];
  }

  // Spor için chip widget
  static Widget buildSportChip(
    BuildContext context,
    String sport, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final color = getColorForSport(sport);
    final icon = getIconForSport(sport);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              sport,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
