import 'package:flutter/material.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ExercisesTab extends StatelessWidget {
  const ExercisesTab({
    super.key,
    required this.catalog,
    required this.category,
    required this.onCategory,
    required this.onOpenExercise,
  });

  final TrainingCatalog catalog;
  final ExerciseCategory? category;
  final ValueChanged<ExerciseCategory?> onCategory;
  final ValueChanged<CatalogExercise> onOpenExercise;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = category == null
        ? catalog.exercises
        : catalog.exercises.where((e) => e.category == category).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Catalogue par famille — force, Hyrox, cardio, mobilité.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ApexChip(
                label: 'Tous',
                selected: category == null,
                accent: AppColors.cyan,
                onTap: () => onCategory(null),
              ),
              const SizedBox(width: 8),
              for (final cat in ExerciseCategory.values) ...[
                ApexChip(
                  label: cat.label,
                  selected: category == cat,
                  accent: cat.accent,
                  onTap: () => onCategory(cat),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final ex in items) ...[
          ApexCard(
            tone: ApexCardTone.elevated,
            accent: ex.category.accent,
            onTap: () => onOpenExercise(ex),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ex.category.accent.withValues(alpha: 0.14),
                    borderRadius: AppRadii.smAll,
                  ),
                  child: Icon(Icons.fitness_center_rounded, color: ex.category.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: text.titleMedium),
                      Text(
                        '${ex.category.label}  ·  ${ex.muscles}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                      Text(ex.lastPerf, style: text.labelMedium?.copyWith(color: AppColors.cyan)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
