import 'package:flutter/material.dart';

/// Modern ve şık spor uygulaması için özel renk paleti
class AppColors {
  // Ana renkler - Derin mavi ve canlı turuncu kombinasyonu
  static const Color primary = Color(0xFF1E3A8A); // Derin lacivert mavi
  static const Color primaryLight = Color(0xFF3B82F6); // Açık mavi
  static const Color primaryDark = Color(0xFF1E40AF); // Koyu mavi

  // Vurgu renkleri - Enerjik turuncu/amber tonları
  static const Color accent = Color(0xFFFF6B35); // Canlı turuncu
  static const Color accentLight = Color(0xFFFF8C61); // Açık turuncu
  static const Color accentDark = Color(0xFFE55A2B); // Koyu turuncu

  // İkincil renkler
  static const Color secondary = Color(0xFF10B981); // Başarı yeşili
  static const Color secondaryLight = Color(0xFF34D399); // Açık yeşil

  // Nötr renkler - Modern ve temiz görünüm için
  static const Color background = Color(0xFFF8FAFC); // Çok açık gri-mavi
  static const Color surface = Color(0xFFFFFFFF); // Beyaz
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Açık gri

  // Metin renkler
  static const Color textPrimary = Color(0xFF0F172A); // Neredeyse siyah
  static const Color textSecondary = Color(0xFF64748B); // Orta gri
  static const Color textTertiary = Color(0xFF94A3B8); // Açık gri
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Beyaz

  // Durum renkleri
  static const Color success = Color(0xFF10B981); // Yeşil
  static const Color warning = Color(0xFFF59E0B); // Sarı
  static const Color error = Color(0xFFEF4444); // Kırmızı
  static const Color info = Color(0xFF3B82F6); // Mavi

  // Sınır ve bölücü renkleri
  static const Color border = Color(0xFFE2E8F0); // Açık gri
  static const Color divider = Color(0xFFCBD5E1); // Orta açık gri

  // Gölge renkleri
  static const Color shadow = Color(0x1A000000); // %10 siyah
  static const Color shadowLight = Color(0x0D000000); // %5 siyah

  // Gradient'ler
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spor türlerine göre renkler
  static const Color tennisColor = Color(0xFFDCF70C); // Tenis topu sarısı
  static const Color footballColor = Color(0xFF10B981); // Futbol sahası yeşili
  static const Color basketballColor = Color(0xFFFF6B35); // Basketbol topu turuncusu
  static const Color volleyballColor = Color(0xFF3B82F6); // Voleybol mavisi
  static const Color badmintonColor = Color(0xFFF59E0B); // Badminton sarısı
  static const Color tableTennisColor = Color(0xFFEF4444); // Masa tenisi kırmızısı
}
