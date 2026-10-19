import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/mock_repositories.dart';
import '../../core/app_scope.dart';
import '../../core/api/repositories.dart';
import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import '../onboarding/onboarding_flow_screen.dart';
import 'goals_tab.dart';
import 'measures_tab.dart';
import 'profile_edit_screen.dart';
import 'profile_overview_tab.dart';

class ProfileModuleScreen extends StatefulWidget {
  const ProfileModuleScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<ProfileModuleScreen> createState() => _ProfileModuleScreenState();
}

class _ProfileModuleScreenState extends State<ProfileModuleScreen> {
  ProfileBundle? _data;
  String? _error;
  bool _loading = true;
  late ProfileRepository _repository;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      _repository = AppScope.maybeOf(context)?.profile ?? MockProfileRepository();
      final data = await _repository.loadProfile();
      if (mounted) setState(() { _data = data; _loading = false; });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit() async {
    final current = _data;
    if (current == null) return;
    final updated = await Navigator.of(context).push<SportProfile>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(profile: current.profile),
      ),
    );
    if (updated != null) {
      if (!mounted) return;
      try {
        final saved = await _repository.updateProfile(updated);
        if (mounted) setState(() => _data = current.copyWith(profile: saved));
      } on ApiException catch (error) {
        _showError(error.message);
      }
    }
  }

  Future<void> _setLevel(SportLevel level) async {
    final current = _data;
    if (current == null) return;
    try {
      final saved = await _repository.updateProfile(current.profile.copyWith(level: level));
      if (mounted) setState(() => _data = current.copyWith(profile: saved));
    } on ApiException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _toggleSport(String sport) async {
    final current = _data;
    if (current == null) return;
    final next = {...current.profile.sports};
    if (next.contains(sport) && next.length > 1) {
      next.remove(sport);
      try {
        final saved = await _repository.updateProfile(current.profile.copyWith(sports: next));
        if (mounted) setState(() => _data = current.copyWith(profile: saved));
      } on ApiException catch (error) {
        _showError(error.message);
      }
    }
  }

  Future<void> _setPrimary(GoalKind kind) async {
    final current = _data;
    final matches = current?.goals.where((item) => item.kind == kind).toList() ?? const <SportGoal>[];
    final goal = matches.isEmpty ? null : matches.first;
    if (current == null || goal?.id == null) return;
    try {
      final saved = await _repository.updateGoal(goal!.copyWith(primary: true, active: true));
      if (mounted) setState(() => _data = current.copyWith(goals: current.goals.map((item) => item.id == saved.id ? saved : item.copyWith(primary: false)).toList()));
    } on ApiException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _toggleGoal(GoalKind kind) async {
    final current = _data;
    final matches = current?.goals.where((item) => item.kind == kind).toList() ?? const <SportGoal>[];
    final goal = matches.isEmpty ? null : matches.first;
    if (current == null || goal?.id == null) return;
    try {
      final saved = await _repository.updateGoal(goal!.copyWith(active: !goal.active, primary: goal.active ? false : goal.primary));
      if (mounted) setState(() => _data = current.copyWith(goals: current.goals.map((item) => item.id == saved.id ? saved : item).toList()));
    } on ApiException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _addGoal(SportGoal goal) async {
    final current = _data;
    if (current == null) return;
    try {
      await _repository.createGoal(goal);
      final goals = await _repository.loadGoals();
      if (mounted) setState(() => _data = current.copyWith(goals: goals));
    } on ApiException catch (error) { _showError(error.message); }
  }

  Future<void> _deleteGoal(SportGoal goal) async {
    final current = _data;
    if (current == null || goal.id == null) return;
    try {
      await _repository.deleteGoal(goal.id!);
      if (mounted) setState(() => _data = current.copyWith(goals: current.goals.where((item) => item.id != goal.id).toList()));
    } on ApiException catch (error) { _showError(error.message); }
  }

  Future<void> _addMeasure(BodySnapshot snap) async {
    final current = _data;
    if (current == null) return;
    try {
      await _repository.addMeasurement(snap);
      final measurements = await _repository.loadMeasurements();
      if (!mounted) return;
      setState(() => _data = current.copyWith(measurements: measurements));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relevé ajouté à l\'historique')),
      );
    } on ApiException catch (error) {
      _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const tabs = ['Profil', 'Objectifs', 'Mesures'];

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_data == null) return Scaffold(body: Center(child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(_error ?? 'Réessayer'))));
    final data = _data!;

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
                        Text('Utilisateurs', style: text.labelSmall),
                        Text('Profils sportifs', style: text.headlineMedium),
                      ],
                    ),
                  ),
                  ApexAvatar(initials: data.profile.initials, size: 40),
                  if (widget.onLogout != null)
                    ApexIconButton(
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        try {
                          await AppScope.of(context).auth.logout();
                        } finally {
                          widget.onLogout!();
                        }
                      },
                    ),
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
                  ProfileOverviewTab(
                    profile: data.profile,
                    onEdit: _edit,
                    onLevelChanged: _setLevel,
                    onToggleSport: _toggleSport,
                    onRedoOnboarding: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => OnboardingFlowScreen(
                            onFinished: () {
                              Navigator.of(context).pop();
                              _load();
                            },
                          ),
                        ),
                      );
                      _load();
                    },
                  ),
                  GoalsTab(
                    goals: data.goals,
                    onSetPrimary: _setPrimary,
                    onToggleActive: _toggleGoal,
                    onAdd: _addGoal,
                    onDelete: _deleteGoal,
                  ),
                  MeasuresTab(
                    measurements: data.measurements,
                    activity: data.activity,
                    heightCm: data.profile.heightCm,
                    onAddMeasure: _addMeasure,
                  ),
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
          color: selected ? AppColors.volt : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.textOnVolt : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
