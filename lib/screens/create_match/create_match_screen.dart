import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/screens/create_match/steps/sport_selection_step.dart';
import 'package:playmatchr/screens/create_match/steps/match_details_step.dart';
import 'package:playmatchr/screens/create_match/steps/location_selection_step.dart';
import 'package:playmatchr/screens/create_match/steps/players_selection_step.dart';
import 'package:playmatchr/screens/create_match/steps/additional_info_step.dart';

class CreateMatchScreen extends StatelessWidget {
  const CreateMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateMatchController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentStepTitle)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            controller.reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Obx(() => LinearProgressIndicator(
                value: controller.progress,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              )),

          // Step Content
          Expanded(
            child: Obx(() {
              switch (controller.currentStep.value) {
                case 0:
                  return const SportSelectionStep();
                case 1:
                  return const MatchDetailsStep();
                case 2:
                  return const LocationSelectionStep();
                case 3:
                  return const PlayersSelectionStep();
                case 4:
                  return const AdditionalInfoStep();
                default:
                  return const SizedBox();
              }
            }),
          ),

          // Navigation Buttons
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Geri butonu
                  Obx(() => controller.currentStep.value > 0
                      ? Expanded(
                          child: OutlinedButton(
                            onPressed: controller.previousStep,
                            child: const Text('Geri'),
                          ),
                        )
                      : const SizedBox()),

                  if (controller.currentStep.value > 0)
                    const SizedBox(width: AppSpacing.lg),

                  // İleri/Oluştur butonu
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.isCreating.value
                              ? null
                              : controller.nextStep,
                          child: controller.isCreating.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textOnPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  controller.currentStep.value ==
                                          controller.totalSteps - 1
                                      ? 'Maç Oluştur'
                                      : 'İleri',
                                ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
