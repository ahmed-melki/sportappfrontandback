import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/mock_repositories.dart';
import '../../core/app_scope.dart';
import '../../core/api/repositories.dart';
import '../../data/mock_training.dart' show expressSessionFor;
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'exercise_detail_screen.dart';
import 'exercises_tab.dart';
import 'program_detail_screen.dart';
import 'programs_tab.dart';
import 'progress_tab.dart';
import 'session_player_screen.dart';

class TrainingModuleScreen extends StatefulWidget {
  const TrainingModuleScreen({super.key});

  @override
  State<TrainingModuleScreen> createState() => _TrainingModuleScreenState();
}

class _TrainingModuleScreenState extends State<TrainingModuleScreen> {
  TrainingCatalog? _catalog;
  String? _error;
  bool _loading = true;
  late TrainingRepository _repository;
  int _tab = 0;
  ExerciseCategory? _category;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      _repository = AppScope.maybeOf(context)?.training ?? MockTrainingRepository();
      final catalog = await _repository.loadCatalog();
      if (mounted) setState(() { _catalog = catalog; _loading = false; });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  Future<void> _play(WorkoutSession session, String programTitle, String programId) async {
    final catalog = _catalog;
    if (catalog == null) return;
    final log = await Navigator.of(context).push<SessionLog>(
      MaterialPageRoute(
        builder: (_) => SessionPlayerScreen(
          catalog: catalog,
          session: session,
          programTitle: programTitle,
          onComplete: (sets) => _repository.createSessionLog(sessionId: session.id, programId: programId, completedAt: DateTime.now().toUtc(), durationMin: session.durationMin, highlight: '${session.title} terminée', sets: sets),
        ),
      ),
    );
    if (!mounted || log == null) return;
    setState(() {
      _catalog = catalog.copyWith(logs: [log, ...catalog.logs]);
      _tab = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Séance ajoutée à l\'historique')),
    );
  }

  Future<void> _openExercise(CatalogExercise exercise) async {
    final catalog = _catalog;
    if (catalog == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exercise: exercise,
          onStartExpress: () {
              _play(
              expressSessionFor(exercise.id),
              exercise.name,
                'five-five',
            );
          },
        ),
      ),
    );
  }

  Future<void> _openProgram(TrainingProgram program) async {
    final catalog = _catalog;
    if (catalog == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(
          catalog: catalog,
          program: program,
          onStartSession: (session) => _play(session, program.title, program.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final catalog = _catalog;
    if (catalog == null) return Scaffold(body: Center(child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(_error ?? 'Réessayer'))));
    const tabs = ['Exercices', 'Programmes', 'Progression'];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  ApexIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entraînement', style: text.labelSmall),
                        Text('Exercices & programmes', style: text.headlineMedium),
                      ],
                    ),
                  ),
                  Icon(Icons.bolt_rounded, color: AppColors.cyan.withValues(alpha: 0.9)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(
                        child: _TabPill(
                          label: tabs[i],
                          selected: _tab == i,
                          onTap: () => setState(() => _tab = i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  ExercisesTab(
                    catalog: catalog,
                    category: _category,
                    onCategory: (c) => setState(() => _category = c),
                    onOpenExercise: _openExercise,
                  ),
                  ProgramsTab(
                    catalog: catalog,
                    onOpenProgram: _openProgram,
                  ),
                  ProgressTab(catalog: catalog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.textOnVolt : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
