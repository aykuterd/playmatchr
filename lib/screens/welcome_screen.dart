import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.accent.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingXXL,
            child: Column(
              children: [
                // Logo ve başlık bölümü
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo - Spor ikonu
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.sports_tennis,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // App ismi
                      Text(
                        'PlayMatchr',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  blurRadius: 20.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Slogan
                      Text(
                        'Spor tutkunlarını buluşturan platform',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),

                // Özellikler bölümü
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureItem(
                        context,
                        Icons.people_outline,
                        'Yakınındaki sporcuları bul',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeatureItem(
                        context,
                        Icons.calendar_today_outlined,
                        'Maç planla ve organize et',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeatureItem(
                        context,
                        Icons.sports_outlined,
                        'Farklı spor dallarında etkinlik',
                      ),
                    ],
                  ),
                ),

                // Butonlar bölümü
                Column(
                  children: [
                    // Başla butonu
                    GradientButton(
                      text: 'Başla',
                      width: double.infinity,
                      gradient: const LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white,
                        ],
                      ),
                      onPressed: () {
                        Get.toNamed('/signup');
                      },
                    ).withTextColor(AppColors.primary),

                    const SizedBox(height: AppSpacing.lg),

                    // Giriş yap butonu
                    OutlinedButton(
                      onPressed: () {
                        Get.toNamed('/signin');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Giriş Yap'),
                    ),

                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

// GradientButton için extension
extension GradientButtonExtension on GradientButton {
  Widget withTextColor(Color color) {
    return Builder(
      builder: (context) {
        return Container(
          width: width,
          height: height ?? 56,
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusLG,
            boxShadow: onPressed != null ? AppSpacing.shadowMD : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: AppSpacing.borderRadiusLG,
              child: Container(
                padding: AppSpacing.paddingHorizontalXL,
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            text,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: color,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
