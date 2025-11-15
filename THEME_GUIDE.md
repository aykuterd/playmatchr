# PlayMatchr - Tema ve Renk Paleti Rehberi

## 🎨 Renk Paleti

PlayMatchr uygulaması modern, şık ve enerjik bir spor teması kullanıyor.

### Ana Renkler
- **Primary (Lacivert Mavi)**: `#1E3A8A` - Ana butonlar, vurgular
- **Primary Light (Açık Mavi)**: `#3B82F6` - Hover durumları
- **Primary Dark (Koyu Mavi)**: `#1E40AF` - Gradient'ler

### Vurgu Renkleri
- **Accent (Canlı Turuncu)**: `#FF6B35` - CTA butonları, önemli vurgular
- **Accent Light**: `#FF8C61` - Gradient'ler
- **Accent Dark**: `#E55A2B` - Hover durumları

### İkincil Renkler
- **Secondary (Başarı Yeşili)**: `#10B981` - Başarı mesajları
- **Secondary Light**: `#34D399` - Başarı vurguları

### Nötr Renkler
- **Background**: `#F8FAFC` - Ana arka plan
- **Surface**: `#FFFFFF` - Kartlar, modaller
- **Surface Variant**: `#F1F5F9` - Alternatif arka planlar

### Metin Renkleri
- **Text Primary**: `#0F172A` - Ana metinler
- **Text Secondary**: `#64748B` - İkincil metinler
- **Text Tertiary**: `#94A3B8` - Yardımcı metinler
- **Text On Primary**: `#FFFFFF` - Renkli arka plandaki metinler

### Durum Renkleri
- **Success**: `#10B981` - Başarı mesajları
- **Warning**: `#F59E0B` - Uyarı mesajları
- **Error**: `#EF4444` - Hata mesajları
- **Info**: `#3B82F6` - Bilgilendirme mesajları

### Spor Renkleri
Her spor dalı için özel renkler:
- **Tenis**: `#DCF70C` (Tenis topu sarısı)
- **Futbol**: `#10B981` (Sahası yeşili)
- **Basketbol**: `#FF6B35` (Basketbol topu turuncusu)
- **Voleybol**: `#3B82F6` (Voleybol mavisi)
- **Badminton**: `#F59E0B` (Badminton sarısı)
- **Masa Tenisi**: `#EF4444` (Masa tenisi kırmızısı)

## 📏 Spacing (Boşluklar)

Tüm boşluklar 4px biriminin katlarıdır:
- **XS**: 4px
- **SM**: 8px
- **MD**: 12px
- **LG**: 16px
- **XL**: 20px
- **XXL**: 24px
- **XXXL**: 32px

## 🔤 Tipografi

### Fontlar
- **Başlıklar**: Poppins (Bold, Semibold)
- **Gövde Metinleri**: Inter (Regular, Medium)
- **Etiketler**: Poppins (Medium, Semibold)

### Metin Boyutları
- **Display Large**: 56px - Ana başlıklar
- **Display Medium**: 45px - İkincil başlıklar
- **Headline Large**: 32px - Büyük başlıklar
- **Headline Medium**: 28px - Orta başlıklar
- **Title Large**: 20px - Kart başlıkları
- **Body Large**: 16px - Ana metinler
- **Body Medium**: 14px - İkincil metinler
- **Label Large**: 16px - Buton metinleri

## 🔘 Border Radius (Köşe Yuvarlaklığı)

- **SM**: 8px - Küçük elemanlar
- **MD**: 12px - Input'lar, küçük kartlar
- **LG**: 16px - Butonlar, kartlar
- **XL**: 20px - Dialoglar
- **XXL**: 24px - Büyük kartlar
- **Full**: 9999px - Tam yuvarlak

## 🎯 Kullanım Örnekleri

### Tema Renklerini Kullanma
```dart
import 'package:playmatchr/theme/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Merhaba',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

### Spacing Kullanma
```dart
import 'package:playmatchr/theme/app_spacing.dart';

Padding(
  padding: AppSpacing.paddingLG,
  child: YourWidget(),
)
```

### Gradient Button Kullanma
```dart
import 'package:playmatchr/widgets/gradient_button.dart';

GradientButton(
  text: 'Devam Et',
  onPressed: () {},
  gradient: AppColors.primaryGradient,
)
```

### Custom Card Kullanma
```dart
import 'package:playmatchr/widgets/custom_card.dart';

CustomCard(
  onTap: () {},
  child: Text('Kart İçeriği'),
)
```

### Sport Icon Kullanma
```dart
import 'package:playmatchr/widgets/sport_icon.dart';

SportIcon.buildSportChip(
  context,
  SportIcon.tennis,
  isSelected: true,
  onTap: () {},
)
```

### Empty State Kullanma
```dart
import 'package:playmatchr/widgets/empty_state.dart';

EmptyState(
  icon: Icons.sports_tennis,
  title: 'Henüz maç yok',
  message: 'İlk maçınızı oluşturun',
  actionLabel: 'Maç Oluştur',
  onAction: () {},
)
```

## 📱 Ekran Örnekleri

### Welcome Screen
Modern gradient arka plan, özellik listesi ve CTA butonları ile tasarlanmış karşılama ekranı.

### Tutarlılık Kuralları
1. **Renk Kullanımı**: Her zaman `AppColors` sınıfından renkleri kullanın
2. **Spacing**: Her zaman `AppSpacing` sabitlerini kullanın
3. **Tipografi**: Theme'den gelen text style'ları kullanın
4. **Widget'lar**: Özel widget'ları (GradientButton, CustomCard, vb.) tercih edin
5. **Border Radius**: `AppSpacing` sınıfındaki border radius sabitlerini kullanın

## 🎨 Tasarım Prensipleri

1. **Modern ve Temiz**: Minimal ve sade tasarım
2. **Enerjik**: Spor temalı canlı renkler
3. **Profesyonel**: İş görünümlü, kaliteli his
4. **Tutarlı**: Tüm ekranlarda aynı stil
5. **Kullanıcı Dostu**: Kolay okunabilir ve kullanılabilir

## 📦 Dosya Yapısı

```
lib/
├── theme/
│   ├── app_colors.dart      # Renk paleti
│   ├── app_theme.dart       # Ana tema tanımları
│   └── app_spacing.dart     # Boşluk ve spacing sabitleri
├── widgets/
│   ├── gradient_button.dart # Gradient buton widget'ı
│   ├── custom_card.dart     # Özel kart widget'ı
│   ├── sport_icon.dart      # Spor ikonu ve chip widget'ları
│   └── empty_state.dart     # Boş durum widget'ları
└── screens/
    └── ...                  # Uygulama ekranları
```
