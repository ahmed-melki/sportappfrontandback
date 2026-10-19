import 'package:flutter/material.dart';

import '../../data/coach_models.dart';
import '../../data/mock_coaches.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class CoachesModuleScreen extends StatefulWidget {
  const CoachesModuleScreen({super.key});

  @override
  State<CoachesModuleScreen> createState() => _CoachesModuleScreenState();
}

class _CoachesModuleScreenState extends State<CoachesModuleScreen> {
  final _bookings = [...mockCoachBookings];
  final _query = TextEditingController();
  int _tab = 0;
  CoachSpecialty? _specialty;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<CoachProfile> get _coaches => mockCoaches.where((coach) {
    final matchesQuery =
        _query.text.isEmpty ||
        coach.name.toLowerCase().contains(_query.text.toLowerCase()) ||
        coach.role.toLowerCase().contains(_query.text.toLowerCase());
    final matchesSpecialty =
        _specialty == null || coach.specialties.contains(_specialty);
    return matchesQuery && matchesSpecialty;
  }).toList();

  Future<void> _openCoach(CoachProfile coach) async {
    final booking = await Navigator.of(context).push<CoachBooking>(
      MaterialPageRoute(builder: (_) => CoachDetailScreen(coach: coach)),
    );
    if (!mounted || booking == null) return;
    setState(() => _bookings.insert(0, booking));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Réservation confirmée avec ${coach.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const tabs = ['Coachs', 'Réservations', 'Messages', 'Suivi coach'];
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _ModuleHeader(
              title: 'Coachs sportifs',
              eyebrow: 'Accompagnement',
              icon: Icons.diversity_3_rounded,
              accent: AppColors.violet,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: _ModuleTabs(
                tabs: tabs,
                selected: _tab,
                accent: AppColors.violet,
                onSelected: (value) => setState(() => _tab = value),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _buildDirectory(text),
                1 => _buildBookings(text),
                2 => _buildMessages(text),
                _ => _buildCoachView(text),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectory(TextTheme text) {
    final coaches = _coaches;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trouvez votre prochain déclic',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Des experts sélectionnés pour avancer avec un plan qui vous ressemble.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un coach ou une spécialité',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SpecialtyChip(
                        label: 'Tous',
                        selected: _specialty == null,
                        onTap: () => setState(() => _specialty = null),
                      ),
                      for (final specialty in CoachSpecialty.values)
                        _SpecialtyChip(
                          label: specialty.label,
                          accent: specialty.accent,
                          selected: _specialty == specialty,
                          onTap: () => setState(() => _specialty = specialty),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (coaches.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Aucun coach trouvé.', style: text.bodyMedium),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.xxxl,
            ),
            sliver: SliverList.builder(
              itemCount: coaches.length,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CoachCard(
                  coach: coaches[index],
                  onTap: () => _openCoach(coaches[index]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookings(TextTheme text) {
    if (_bookings.isEmpty) {
      return Center(
        child: Text('Aucune réservation à venir.', style: text.bodyMedium),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text('Vos rendez-vous', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Retrouvez vos prochains échanges avec vos coachs.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final booking in _bookings) ...[
          _BookingCard(booking: booking),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildMessages(TextTheme text) {
    final messages = [
      (
        'Marion Leroy',
        'On garde la même charge jeudi, mais ajoutez 5 min de mobilité.',
        '10:42',
        AppColors.coral,
        'ML',
      ),
      (
        'Antoine Bazin',
        'Votre semaine 4 est prête à être validée.',
        'Hier',
        AppColors.cyan,
        'AB',
      ),
      (
        'Inès Roche',
        'J’ai regardé votre journal alimentaire.',
        'Lun.',
        AppColors.mint,
        'IR',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text('Messages', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text('Un canal direct avec vos coachs.', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        for (final message in messages) ...[
          ApexCard(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Conversation avec ${message.$1}')),
            ),
            child: Row(
              children: [
                ApexAvatar(initials: message.$5, size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(message.$1, style: text.titleMedium),
                          ),
                          Text(message.$3, style: text.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildCoachView(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        ApexCard(
          tone: ApexCardTone.glow,
          accent: AppColors.violet,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.violet,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.textOnVolt,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Espace coach', style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '3 sportifs suivis · 8 séances cette semaine',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: ApexStat(
                value: '3',
                label: 'Sportifs',
                accent: AppColors.violet,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ApexStat(
                value: '8',
                label: 'Séances',
                accent: AppColors.cyan,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ApexStat(
                value: '92',
                unit: '%',
                label: 'Présence',
                accent: AppColors.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Mes sportifs', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        for (final athlete in mockAthletesFollowed) ...[
          _AthleteCard(athlete: athlete),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class CoachDetailScreen extends StatefulWidget {
  const CoachDetailScreen({super.key, required this.coach});
  final CoachProfile coach;
  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  String _selectedSlot = 'Jeudi · 18:30';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final coach = widget.coach;
    final slots = ['Jeudi · 18:30', 'Vendredi · 07:30', 'Samedi · 10:00'];
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    ApexIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    ApexIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text('Message envoyé au coach'),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    ApexAvatar(initials: coach.initials, size: 88),
                    const SizedBox(height: AppSpacing.md),
                    Text(coach.name, style: text.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      coach.role,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${coach.rating} · ${coach.reviewCount} avis',
                          style: text.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final specialty in coach.specialties)
                          _SpecialtyChip(
                            label: specialty.label,
                            accent: specialty.accent,
                            selected: true,
                            onTap: () {},
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      coach.bio,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              sliver: SliverList.list(
                children: [
                  Text('Choisir un créneau', style: text.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final slot in slots)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SlotTile(
                        label: slot,
                        selected: _selectedSlot == slot,
                        onTap: () => setState(() => _selectedSlot = slot),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  ApexButton(
                    label: 'Réserver · ${coach.price} €',
                    icon: Icons.event_available_rounded,
                    onPressed: () => Navigator.of(context).pop(
                      CoachBooking(
                        coachName: coach.name,
                        date: _selectedSlot.split(' · ').first,
                        time: _selectedSlot.split(' · ').last,
                        type: 'Consultation individuelle · 45 min',
                        status: 'Confirmé',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({
    required this.title,
    required this.eyebrow,
    required this.icon,
    required this.accent,
  });
  final String title;
  final String eyebrow;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Padding(
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
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: accent),
              ),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        Icon(icon, color: accent),
      ],
    ),
  );
}

class _ModuleTabs extends StatelessWidget {
  const _ModuleTabs({
    required this.tabs,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });
  final List<String> tabs;
  final int selected;
  final Color accent;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.mdAll,
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        for (var index = 0; index < tabs.length; index++)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == index ? accent : Colors.transparent,
                  borderRadius: AppRadii.smAll,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected == index
                        ? AppColors.textOnVolt
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: selected
          ? (accent ?? AppColors.violet)
          : AppColors.surface,
      side: BorderSide(
        color: selected ? (accent ?? AppColors.violet) : AppColors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.textOnVolt : AppColors.textSecondary,
      ),
    ),
  );
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onTap});
  final CoachProfile coach;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      onTap: onTap,
      accent: coach.accent,
      child: Row(
        children: [
          ApexAvatar(initials: coach.initials, size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(coach.name, style: text.titleMedium)),
                    if (coach.isOnline) const _OnlineDot(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  coach.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${coach.rating} · ${coach.reviewCount} avis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${coach.price} € / séance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(color: AppColors.volt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: AppColors.mint,
      shape: BoxShape.circle,
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final CoachBooking booking;
  @override
  Widget build(BuildContext context) => ApexCard(
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.15),
            borderRadius: AppRadii.mdAll,
          ),
          child: const Icon(Icons.event_rounded, color: AppColors.violet),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.coachName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(booking.type, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                '${booking.date} · ${booking.time}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        _StatusPill(label: booking.status),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.mint.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: AppColors.mint),
    ),
  );
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.mdAll,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.violet.withValues(alpha: 0.14)
            : AppColors.surface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(
          color: selected ? AppColors.violet : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.violet : AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    ),
  );
}

class _AthleteCard extends StatelessWidget {
  const _AthleteCard({required this.athlete});
  final AthleteFollowed athlete;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      child: Column(
        children: [
          Row(
            children: [
              ApexAvatar(initials: athlete.initials, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.name, style: text.titleMedium),
                    Text(athlete.goal, style: text.bodySmall),
                  ],
                ),
              ),
              Text(
                '${(athlete.progress * 100).round()}%',
                style: text.labelLarge?.copyWith(color: athlete.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: athlete.progress,
              minHeight: 6,
              color: athlete.accent,
              backgroundColor: athlete.accent.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(athlete.lastSession, style: text.labelSmall),
          ),
        ],
      ),
    );
  }
}
