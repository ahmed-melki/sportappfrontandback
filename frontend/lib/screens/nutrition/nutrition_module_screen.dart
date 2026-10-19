import 'package:flutter/material.dart';

import '../../data/mock_nutrition.dart';
import '../../data/nutrition_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class NutritionModuleScreen extends StatefulWidget {
  const NutritionModuleScreen({super.key});

  @override
  State<NutritionModuleScreen> createState() => _NutritionModuleScreenState();
}

class _NutritionModuleScreenState extends State<NutritionModuleScreen> {
  final _foodQuery = TextEditingController();
  final _favoriteRecipes = <String>{'power-bowl'};
  int _tab = 0;

  @override
  void dispose() {
    _foodQuery.dispose();
    super.dispose();
  }

  List<FoodItem> get _foods => mockFoods
      .where(
        (food) =>
            food.name.toLowerCase().contains(_foodQuery.text.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const tabs = ['Aujourd’hui', 'Journal', 'Recettes', 'Aliments'];
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _NutritionHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: _NutritionTabs(
                tabs: tabs,
                selected: _tab,
                onSelected: (value) => setState(() => _tab = value),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _buildDashboard(text),
                1 => _buildJournal(text),
                2 => _buildRecipes(text),
                _ => _buildFoods(text),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mardi 29 septembre',
                    style: text.labelSmall?.copyWith(color: AppColors.mint),
                  ),
                  const SizedBox(height: 4),
                  Text('Votre fuel du jour', style: text.headlineSmall),
                ],
              ),
            ),
            const Icon(Icons.eco_rounded, color: AppColors.mint, size: 30),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ApexCard(
          tone: ApexCardTone.glow,
          accent: AppColors.mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Énergie consommée', style: text.bodyMedium),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: text.displaySmall,
                            children: const [
                              TextSpan(
                                text: '1 490',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                              TextSpan(
                                text: ' / 2 350 kcal',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.coral,
                    size: 38,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: 0.63,
                  minHeight: 9,
                  color: AppColors.mint,
                  backgroundColor: AppColors.voltGlow,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Il vous reste 860 kcal pour soutenir la séance de ce soir.',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Répartition des macros', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: 'Protéines',
                value: '104 g',
                target: '150 g',
                progress: 0.69,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MacroCard(
                label: 'Glucides',
                value: '168 g',
                target: '260 g',
                progress: 0.65,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MacroCard(
                label: 'Lipides',
                value: '42 g',
                target: '70 g',
                progress: 0.6,
                color: AppColors.violet,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(child: Text('Derniers repas', style: text.headlineSmall)),
            TextButton(
              onPressed: () => setState(() => _tab = 1),
              child: const Text('Voir le journal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final meal in mockMeals.take(2)) ...[
          _MealCard(meal: meal),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildJournal(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Journal alimentaire', style: text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '1 490 kcal · 104 g de protéines',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            ApexIconButton(
              icon: Icons.add_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ajout de repas disponible prochainement'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ApexCard(
          tone: ApexCardTone.muted,
          child: Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: AppColors.mint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Objectif du jour : rester régulier, pas parfait.',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final type in MealType.values) ...[
          Row(
            children: [
              Icon(type.icon, color: AppColors.mint, size: 20),
              const SizedBox(width: 8),
              Text(type.label, style: text.titleMedium),
              const Spacer(),
              if (mockMeals.any((meal) => meal.type == type))
                Text(
                  '${mockMeals.firstWhere((meal) => meal.type == type).calories} kcal',
                  style: text.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...mockMeals
              .where((meal) => meal.type == type)
              .map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MealCard(meal: meal),
                ),
              ),
          if (!mockMeals.any((meal) => meal.type == type))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text('Aucun repas enregistré', style: text.bodySmall),
            ),
        ],
      ],
    );
  }

  Widget _buildRecipes(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Recettes adaptées à votre entraînement',
          style: text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Des idées simples, avec les macros déjà calculées.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final recipe in mockRecipes) ...[
          _RecipeCard(
            recipe: recipe,
            favorite: _favoriteRecipes.contains(recipe.id),
            onFavorite: () => setState(() {
              if (!_favoriteRecipes.add(recipe.id)) {
                _favoriteRecipes.remove(recipe.id);
              }
            }),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${recipe.name} ajoutée à votre sélection'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildFoods(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text('Base d’aliments', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Recherchez une portion pour connaître ses macros.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _foodQuery,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Ex. poulet, riz, skyr',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final food in _foods) ...[
          _FoodCard(food: food),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NutritionHeader extends StatelessWidget {
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
                'Nutrition',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.mint),
              ),
              Text(
                'Alimentation sportive',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const Icon(Icons.restaurant_rounded, color: AppColors.mint),
      ],
    ),
  );
}

class _NutritionTabs extends StatelessWidget {
  const _NutritionTabs({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });
  final List<String> tabs;
  final int selected;
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
                  color: selected == index
                      ? AppColors.mint
                      : Colors.transparent,
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

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
  });
  final String label;
  final String value;
  final String target;
  final double progress;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(value, style: text.titleMedium?.copyWith(color: color)),
          const SizedBox(height: 3),
          Text('/ $target', style: text.labelSmall),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final MealEntry meal;
  @override
  Widget build(BuildContext context) => ApexCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.14),
            borderRadius: AppRadii.mdAll,
          ),
          child: Icon(meal.type.icon, color: AppColors.mint),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '${meal.time} · ${meal.protein} g prot. · ${meal.carbs} g gluc.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          '${meal.calories}\nkcal',
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    ),
  );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });
  final NutritionRecipe recipe;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      onTap: onTap,
      accent: recipe.accent,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: recipe.accent.withValues(alpha: 0.15),
              borderRadius: AppRadii.mdAll,
            ),
            child: Icon(recipe.icon, color: recipe.accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: text.titleMedium),
                const SizedBox(height: 3),
                Text(
                  recipe.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${recipe.calories} kcal · ${recipe.protein} g prot. · ${recipe.duration} min',
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? AppColors.coral : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.food});
  final FoodItem food;
  @override
  Widget build(BuildContext context) => ApexCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '${food.category} · ${food.serving}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${food.calories} kcal',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.mint),
            ),
            const SizedBox(height: 4),
            Text(
              'P ${food.protein} · G ${food.carbs} · L ${food.fat}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    ),
  );
}
