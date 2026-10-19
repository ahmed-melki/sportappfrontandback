import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sport_app_ui/core/api/app_repositories.dart';
import 'package:sport_app_ui/core/app_scope.dart';
import 'package:sport_app_ui/screens/coaches/coaches_module_screen.dart';
import 'package:sport_app_ui/screens/hub_screen.dart';
import 'package:sport_app_ui/screens/nutrition/nutrition_module_screen.dart';
import 'package:sport_app_ui/screens/profile/profile_module_screen.dart';
import 'package:sport_app_ui/screens/shop/shop_module_screen.dart';
import 'package:sport_app_ui/screens/training/training_module_screen.dart';
import 'package:sport_app_ui/theme/app_theme.dart';

Widget _wrap(Widget child) => AppScope(
  repositories: createRepositories(mock: true),
  child: MaterialApp(theme: AppTheme.dark(), home: child),
);

Future<void> _settle(WidgetTester tester, [Duration duration = const Duration(milliseconds: 400)]) async {
  await tester.pump();
  await tester.pump(duration);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Hub APEX s\'affiche', (tester) async {
    await tester.pumpWidget(_wrap(const HubScreen()));
    await _settle(tester);

    expect(find.text('APEX'), findsOneWidget);
    expect(find.textContaining('Cinq univers'), findsOneWidget);
    expect(find.text('Dark athletic × neon volt'), findsOneWidget);
  });

  testWidgets('Module profils : identité, objectifs, mesures', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ProfileModuleScreen()));
    await _settle(tester);

    expect(find.text('Lina Moreau'), findsOneWidget);
    expect(find.text('Avancé'), findsWidgets);

    await tester.tap(find.text('Objectifs'));
    await _settle(tester);
    expect(find.text('Endurance'), findsWidgets);
    expect(find.text('Prise de masse'), findsOneWidget);

    await tester.tap(find.text('Mesures'));
    await _settle(tester);
    expect(find.text('Mensurations actuelles'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Activités'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Activités'), findsOneWidget);
  });

  testWidgets('Hub ouvre le module profils', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const HubScreen()));
    await _settle(tester);

    await tester.tap(find.text('Ouvrir mon profil'));
    await _settle(tester);

    expect(find.text('Profils sportifs'), findsOneWidget);
    expect(find.text('Lina Moreau'), findsOneWidget);
  });

  testWidgets('Module entraînement : exercices, programmes, progression', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TrainingModuleScreen()));
    await _settle(tester);

    expect(find.text('Squat arrière'), findsOneWidget);

    await tester.tap(find.text('Hyrox').first);
    await _settle(tester);
    expect(find.text('Farmer carry'), findsOneWidget);
    expect(find.text('Squat arrière'), findsNothing);

    await tester.tap(find.text('Programmes'));
    await _settle(tester);
    expect(find.text('Hyrox Engine'), findsOneWidget);
    expect(find.text('Force 5×5'), findsOneWidget);

    await tester.tap(find.text('Hyrox Engine'));
    await _settle(tester);
    expect(find.text('S1 · Lower power'), findsOneWidget);
    expect(find.text('Démarrer la séance').first, findsOneWidget);

    await tester.tap(find.text('Démarrer la séance').first);
    await _settle(tester);
    expect(find.text('Valider la série'), findsOneWidget);
    expect(find.text('Squat arrière'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await _settle(tester);

    await tester.tap(find.text('Progression'));
    await _settle(tester);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('S1 · Lower power'), findsWidgets);
  });

  testWidgets('Module boutique : catalogue, détail, panier et commandes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ShopModuleScreen()));
    await _settle(tester);

    expect(find.text('Aero Runner X'), findsOneWidget);
    await tester.tap(find.text('Aero Runner X'));
    await _settle(tester);
    expect(find.text('Avis clients'), findsOneWidget);
    await tester.tap(find.textContaining('Ajouter ·'));
    await _settle(tester, const Duration(milliseconds: 600));

    await tester.tap(find.text('Panier'));
    await _settle(tester);
    expect(find.text('Commander'), findsOneWidget);
    await tester.tap(find.text('Commander'));
    await _settle(tester);
    expect(find.text('Adresse de livraison'), findsOneWidget);
    expect(find.text('Paiement à la livraison'), findsOneWidget);
  });

  testWidgets('Module coachs : recherche, réservation et suivi', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const CoachesModuleScreen()),
    );
    await tester.pump();

    expect(find.text('Marion Leroy'), findsOneWidget);
    await tester.tap(find.text('Marion Leroy'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir un créneau'), findsOneWidget);
    await tester.tap(find.textContaining('Réserver ·'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Réservations'));
    await tester.pump();
    expect(find.text('Marion Leroy'), findsWidgets);
    expect(find.text('Confirmé'), findsWidgets);
  });

  testWidgets('Module nutrition : dashboard, recettes et aliments', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const NutritionModuleScreen()),
    );
    await tester.pump();

    expect(find.text('Répartition des macros'), findsOneWidget);
    await tester.tap(find.text('Recettes'));
    await tester.pump();
    expect(find.text('Power bowl poulet'), findsOneWidget);
    await tester.tap(find.text('Aliments'));
    await tester.pump();
    expect(find.text('Base d’aliments'), findsOneWidget);
    expect(find.text('Blanc de poulet rôti'), findsOneWidget);
  });
}
