import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:playmatchr/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 28, // Default radius for social screen cards
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(Icons.person, size: radius, color: AppColors.primary),
      );
    }

    if (photoUrl!.startsWith('data:image')) {
      final UriData? data = Uri.parse(photoUrl!).data;
      if (data != null) {
        final bytes = data.contentAsBytes();
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoUrl!),
      backgroundColor: AppColors.primary.withOpacity(0.1),
    );
  }
}
