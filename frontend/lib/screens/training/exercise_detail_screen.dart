import 'package:flutter/material.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.onStartExpress,
  });

  final CatalogExercise exercise;
  final VoidCallback onStartExpress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              children: [
                ApexIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(exercise.name, style: text.headlineMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ApexCard(
              tone: ApexCardTone.glow,
              accent: exercise.category.accent,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.category.label.toUpperCase(), style: text.labelSmall),
                  const SizedBox(height: 8),
                  Text(exercise.cue, style: text.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Matériel', style: text.labelSmall),
                  const SizedBox(height: 6),
                  Text(exercise.equipment, style: text.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Muscles', style: text.labelSmall),
                  const SizedBox(height: 6),
                  Text(exercise.muscles, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text('Dernière perf', style: text.labelSmall),
                  const SizedBox(height: 6),
                  Text(exercise.lastPerf, style: text.headlineSmall?.copyWith(color: AppColors.volt)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ApexButton(
              label: 'Séance express',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                onStartExpress();
              },
            ),
          ],
        ),
      ),
    );
  }
}
