import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/api/repositories.dart';
import '../core/api/mock_repositories.dart';
import '../data/mock_athlete.dart';
import '../data/profile_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/module_accents.dart';
import '../widgets/widgets.dart';
import 'coaches/coaches_module_screen.dart';
import 'nutrition/nutrition_module_screen.dart';
import 'profile/profile_module_screen.dart';
import 'shop/shop_module_screen.dart';
import 'training/training_module_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key, this.onLogout});
  final VoidCallback? onLogout;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  DashboardData? _dashboard;
  SportProfile? _profile;
  Map<String, dynamic>? _activeProgram;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDashboard);
  }

  Future<void> _loadDashboard() async {
    try {
      final repository = AppScope.maybeOf(context)?.profile ?? MockProfileRepository();
      final dashboard = await repository.loadDashboard();
      if (mounted) setState(() => _dashboard = dashboard);
      final profile = await repository.loadProfile();
      if (mounted) setState(() => _profile = profile.profile);
      final programs = await repository.loadUserPrograms();
      if (mounted) {
        final active = programs.firstWhere(
          (p) => p['status'] == 'active',
          orElse: () => programs.isNotEmpty ? programs.first : <String, dynamic>{},
        );
        setState(() => _activeProgram = active.isNotEmpty ? active : null);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger le dashboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final athlete = mockAthlete;
    final firstName = _dashboard?.firstName.isNotEmpty == true ? _dashboard!.firstName : athlete.firstName;
    final readiness = _dashboard?.readiness ?? athlete.readiness;
    final streakDays = _dashboard?.streakDays ?? athlete.streakDays;
    final weeklySessions = _dashboard?.weeklySessions ?? athlete.weeklySessions;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12180C), AppColors.scaffold, Color(0xFF0A1214)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl),
                sliver: SliverList.list(
                  children: [
                    Row(children: [
                      Text('APEX', style: text.headlineLarge),
                      const SizedBox(width: 8),
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.volt, shape: BoxShape.circle)),
                      const Spacer(),
                      const ApexIconButton(icon: Icons.notifications_none_rounded),
                      const SizedBox(width: 8),
                      ApexAvatar(initials: _profile?.initials ?? athlete.initials),
                      if (widget.onLogout != null) ...[
                        const SizedBox(width: 8),
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
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Bonjour, $firstName.', style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Text('Cinq univers.\nUne cadence.', style: text.displayMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Profils, entraînement, boutique, coachs et nutrition — une seule expérience sombre, nette, volt.', style: text.bodyMedium),
                    const SizedBox(height: AppSpacing.xl),
                    ApexCard(
                      tone: ApexCardTone.glow,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('IDENTITÉ VISUELLE', style: text.labelSmall),
                        const SizedBox(height: 8),
                        Text('Dark athletic × neon volt', style: text.headlineSmall),
                        const SizedBox(height: 6),
                        Text('Cartes bordées, CTA lime, accents par module. Réutilise AppColors, ApexCard et ApexButton partout.', style: text.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(spacing: 8, runSpacing: 8, children: const [
                          ApexChip(label: 'Force', selected: true),
                          ApexChip(label: 'Endurance'),
                          ApexChip(label: 'Mobility'),
                          ApexChip(label: 'Hyrox', accent: AppColors.cyan, selected: true),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        ApexButton(label: 'Ouvrir mon profil', icon: Icons.north_east_rounded, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileModuleScreen(onLogout: widget.onLogout)))),
                      ]),
                    ),
                    if (_activeProgram != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Builder(builder: (context) {
                        final rawProg = _activeProgram!['program'];
                        final prog = rawProg is Map ? rawProg : _activeProgram!;
                        final title = prog['title']?.toString() ?? 'Programme en cours';
                        final subtitle = prog['subtitle']?.toString() ?? 'Suis ton plan d\'entraînement personnalisé.';
                        final weeks = prog['weeks'] != null ? '${prog['weeks']} sem.' : null;
                        final days = prog['daysPerWeek'] != null ? '${prog['daysPerWeek']}j/sem.' : null;
                        final level = prog['level']?.toString();

                        return ApexCard(
                          tone: ApexCardTone.glow,
                          accent: AppColors.volt,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.volt.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.volt),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'PROGRAMME RECOMMANDÉ ACTIF',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.labelSmall?.copyWith(
                                                color: AppColors.volt,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (weeks != null)
                                    ApexChip(label: weeks, selected: true, accent: AppColors.volt),
                                  if (days != null)
                                    ApexChip(label: days, accent: AppColors.cyan, selected: true),
                                  if (level != null)
                                    ApexChip(label: level.toUpperCase(), accent: AppColors.violet),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ApexButton(
                                label: 'Continuer l\'entraînement',
                                icon: Icons.play_arrow_rounded,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const TrainingModuleScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Row(children: [
                      Expanded(child: ApexStat(value: '$readiness', unit: '%', label: 'Readiness', accent: AppColors.volt)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: ApexStat(value: '$streakDays', unit: 'j', label: 'Streak', accent: AppColors.cyan)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: ApexStat(value: '$weeklySessions', label: 'Séances', accent: AppColors.violet)),
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                    const ApexSectionHeader(title: 'Modules'),
                    const SizedBox(height: AppSpacing.md),
                    for (final module in ApexModule.values) ...[
                      ModulePreviewCard(
                        module: module,
                        comingSoon: false,
                        onTap: () {
                          final screen = switch (module) {
                            ApexModule.profiles => ProfileModuleScreen(onLogout: widget.onLogout),
                            ApexModule.training => const TrainingModuleScreen(),
                            ApexModule.shop => const ShopModuleScreen(),
                            ApexModule.coaches => const CoachesModuleScreen(),
                            ApexModule.nutrition => const NutritionModuleScreen(),
                          };
                          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (_error != null) TextButton.icon(onPressed: _loadDashboard, icon: const Icon(Icons.refresh), label: Text(_error!)),
                    Text('${athlete.fullName}  ·  ${athlete.sport}  ·  ${athlete.level}', textAlign: TextAlign.center, style: text.labelSmall),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
