import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class AdditionalInfoStep extends StatelessWidget {
  const AdditionalInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateMatchController>();

    return SingleChildScrollView(
      padding: AppSpacing.paddingXXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ek Bilgiler', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxxl),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Maliyet (₺)',
              hintText: 'Kişi başı maliyet (opsiyonel)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.costPerPerson.value = double.tryParse(value);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Notlar',
              hintText: 'Ek bilgiler, talimatlar... (opsiyonel)',
            ),
            maxLines: 3,
            onChanged: (value) => controller.notes.value = value,
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bu adım tamamen opsiyonel. Doğrudan "Maç Oluştur" diyebilirsin.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
