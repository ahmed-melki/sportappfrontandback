import 'package:flutter/material.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ProgramsTab extends StatelessWidget {
  const ProgramsTab({
    super.key,
    required this.catalog,
    required this.onOpenProgram,
  });

  final TrainingCatalog catalog;
  final ValueChanged<TrainingProgram> onOpenProgram;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Plans complets : séances, volumes, puis tu lances le live.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final program in catalog.programs) ...[
          ApexCard(
            tone: ApexCardTone.glow,
            accent: AppColors.cyan,
            onTap: () => onOpenProgram(program),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.14),
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
                      ),
                      child: Text(
                        program.level,
                        style: text.labelMedium?.copyWith(color: AppColors.cyan),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.bolt_rounded, color: AppColors.cyan.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(program.title, style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(program.subtitle, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${program.weeks} sem.  ·  ${program.daysPerWeek} j / sem.  ·  ${program.sessionIds.length} séances type',
                  style: text.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
