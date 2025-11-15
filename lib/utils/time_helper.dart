import 'package:flutter/material.dart';

class TimeHelper {
  /// Son görülme zamanını kullanıcı dostu formata çevir
  static String getLastSeenText(DateTime? lastSeen) {
    if (lastSeen == null) return 'Bilinmiyor';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Şu an aktif';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    }
  }

  /// Aktiflik durumunu renk olarak döndür
  static Color getLastSeenColor(DateTime? lastSeen) {
    if (lastSeen == null) return Colors.grey;

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return Colors.green; // Şu an aktif
    } else if (difference.inMinutes < 60) {
      return Colors.orange; // Son 1 saat içinde
    } else {
      return Colors.grey; // Offline
    }
  }

  /// Aktiflik ikonu döndür (online/offline nokta)
  static Widget getOnlineIndicator(DateTime? lastSeen, {double size = 10}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: getLastSeenColor(lastSeen),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  /// Kısa format - sadece "Aktif", "15d önce" gibi
  static String getLastSeenShort(DateTime? lastSeen) {
    if (lastSeen == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Aktif';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}h';
    }
  }
}
