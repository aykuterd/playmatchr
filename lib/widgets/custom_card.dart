import 'package:flutter/material.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

/// Modern özel card widget'ı
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      margin: margin ?? AppSpacing.paddingSM,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: elevation != null && elevation! > 0
            ? AppSpacing.shadowMD
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLG,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: padding ?? AppSpacing.paddingLG,
              child: child,
            ),
          ),
        ),
      ),
    );

    return widget;
  }
}

/// Profil kartı için özel widget
class ProfileCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileCard({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),

          // İsim ve subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
