import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({
    super.key,
    required this.catalog,
    required this.session,
    required this.programTitle,
    this.onComplete,
  });

  final TrainingCatalog catalog;
  final WorkoutSession session;
  final String programTitle;
  final Future<SessionLog> Function(List<Map<String, dynamic>> sets)? onComplete;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _LiveSet {
  _LiveSet({required this.reps, required this.loadKg});

  int reps;
  double loadKg;
  bool done = false;
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen> {
  late final List<List<_LiveSet>> _sets;
  int _ex = 0;
  int _set = 0;
  bool _resting = false;
  int _restLeft = 0;
  Timer? _timer;

  WorkoutSession get session => widget.session;

  SessionExercise get rx => session.exercises[_ex];

  CatalogExercise get exercise => widget.catalog.exerciseById(rx.exerciseId);

  @override
  void initState() {
    super.initState();
    _sets = [
      for (final block in session.exercises)
        List.generate(
          block.sets,
          (_) => _LiveSet(reps: block.reps, loadKg: block.loadKg),
        ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _metricLabel {
    return switch (rx.kind) {
      RxKind.load => 'Charge (kg)',
      RxKind.distance =>
        rx.unitNote == 's' ? 'Temps (s)' : 'Distance (${rx.unitNote ?? 'm'})',
      RxKind.bodyweight => rx.unitNote == 's' ? 'Temps (s)' : 'Répétitions',
    };
  }

  String get _repsLabel {
    if (rx.kind == RxKind.distance) {
      return rx.unitNote == 's' ? 'Secondes' : 'Distance';
    }
    return 'Répétitions';
  }

  void _adjustReps(int d) {
    setState(() {
      final s = _sets[_ex][_set];
      s.reps = (s.reps + d).clamp(1, 999);
    });
  }

  void _adjustLoad(double d) {
    setState(() {
      final s = _sets[_ex][_set];
      s.loadKg = (s.loadKg + d).clamp(0, 400);
    });
  }

  void _completeSet() {
    _timer?.cancel();
    setState(() {
      _sets[_ex][_set].done = true;
    });

    final lastSet = _set >= rx.sets - 1;
    final lastEx = _ex >= session.exercises.length - 1;
    if (lastSet && lastEx) {
      _finish();
      return;
    }

    if (!lastSet) {
      setState(() {
        _resting = true;
        _restLeft = rx.restSec;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_restLeft <= 1) {
          t.cancel();
          setState(() {
            _resting = false;
            _set += 1;
          });
        } else {
          setState(() => _restLeft -= 1);
        }
      });
    } else {
      setState(() {
        _ex += 1;
        _set = 0;
        _resting = false;
      });
    }
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _resting = false;
      if (_set < rx.sets - 1) {
        _set += 1;
      }
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    var volume = 0;
    for (var i = 0; i < session.exercises.length; i++) {
      final block = session.exercises[i];
      if (block.kind != RxKind.load) continue;
      for (final s in _sets[i]) {
        volume += (s.reps * s.loadKg).round();
      }
    }
    final sets = <Map<String, dynamic>>[];
    for (var exerciseIndex = 0; exerciseIndex < session.exercises.length; exerciseIndex++) {
      final block = session.exercises[exerciseIndex];
      for (var setIndex = 0; setIndex < _sets[exerciseIndex].length; setIndex++) {
        final liveSet = _sets[exerciseIndex][setIndex];
        sets.add({'exerciseId': block.exerciseId, 'setNumber': setIndex + 1, 'reps': liveSet.reps, 'loadKg': liveSet.loadKg, 'kind': block.kind.name});
      }
    }
    if (widget.onComplete != null) {
      try {
        final saved = await widget.onComplete!(sets);
        if (mounted) Navigator.of(context).pop(saved);
      } on ApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
      return;
    }
    final log = SessionLog(
      date: DateTime.now(),
      sessionTitle: session.title,
      programTitle: widget.programTitle,
      durationMin: session.durationMin,
      volumeKg: volume,
      highlight: '${exercise.name} série ${_set + 1}',
    );
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = _sets[_ex][_set];
    final showLoad =
        rx.kind == RxKind.load || (rx.kind == RxKind.distance && rx.loadKg > 0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ApexIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.programTitle, style: text.labelSmall),
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(99),
                        ),
                        child: LinearProgressIndicator(
                          value:
                              (_ex + (_set / rx.sets)) /
                              session.exercises.length,
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exercice ${_ex + 1}/${session.exercises.length}  ·  Série ${_set + 1}/${rx.sets}',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(exercise.name, style: text.displaySmall),
                      Text(exercise.cue, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      if (_resting)
                        ApexCard(
                          tone: ApexCardTone.glow,
                          accent: AppColors.cyan,
                          child: Column(
                            children: [
                              Text('TEMPS DE REPOS', style: text.labelSmall),
                              const SizedBox(height: 8),
                              Text(
                                '$_restLeft s',
                                style: text.displayMedium?.copyWith(
                                  color: AppColors.cyan,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ApexButton(
                                label: 'Passer le repos',
                                variant: ApexButtonVariant.secondary,
                                onPressed: _skipRest,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _StepperCard(
                                label: _repsLabel,
                                value:
                                    rx.kind == RxKind.load ||
                                        rx.kind == RxKind.bodyweight
                                    ? '${current.reps}'
                                    : '${current.reps} ${rx.unitNote ?? ''}',
                                onMinus: () => _adjustReps(-1),
                                onPlus: () => _adjustReps(1),
                              ),
                            ),
                            if (showLoad) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _StepperCard(
                                  label: _metricLabel,
                                  value:
                                      current.loadKg ==
                                          current.loadKg.roundToDouble()
                                      ? '${current.loadKg.round()}'
                                      : current.loadKg.toStringAsFixed(1),
                                  onMinus: () => _adjustLoad(-2.5),
                                  onPlus: () => _adjustLoad(2.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < rx.sets; i++)
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _sets[_ex][i].done
                                      ? AppColors.volt
                                      : (i == _set
                                            ? AppColors.cyan.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppColors.surface),
                                  borderRadius: AppRadii.smAll,
                                  border: Border.all(
                                    color: i == _set
                                        ? AppColors.cyan
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: text.labelMedium?.copyWith(
                                    color: _sets[_ex][i].done
                                        ? AppColors.textOnVolt
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!_resting)
                ApexButton(
                  label: 'Valider la série',
                  icon: Icons.check_rounded,
                  onPressed: _completeSet,
                ),
              const SizedBox(height: AppSpacing.sm),
              ApexButton(
                label: 'Terminer la séance',
                variant: ApexButtonVariant.ghost,
                onPressed: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: onMinus),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall,
                ),
              ),
              _RoundBtn(icon: Icons.add, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
