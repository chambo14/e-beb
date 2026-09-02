import 'package:e_beb_app/core/providers/core_providers.dart';
import 'package:e_beb_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/token_storage_memoire.dart';

/// Régression : `showDatePicker(locale: Locale('fr'))` est utilisé par le
/// formulaire d'inscription et par les objectifs d'épargne. Sans les délégués
/// `GlobalMaterialLocalizations` dans MaterialApp, il lève
/// « No MaterialLocalizations found » au lieu d'ouvrir le calendrier.
void main() {
  /// Lit la configuration réelle déclarée dans `main.dart`.
  Future<MaterialApp> materialAppDeLApplication(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(TokenStorageMemoire()),
        ],
        child: const EbebApp(),
      ),
    );
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  testWidgets('l\'application déclare le français et ses délégués', (
    tester,
  ) async {
    final app = await materialAppDeLApplication(tester);

    expect(app.locale, const Locale('fr'));
    expect(app.supportedLocales, contains(const Locale('fr')));
    expect(
      app.localizationsDelegates,
      isNotNull,
      reason: 'sans délégués, tout sélecteur de date en français plante',
    );

    // Laisse expirer le minuteur de redirection du splash.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('le sélecteur de date s\'ouvre en français', (tester) async {
    // La surface de test par défaut (800x600) est trop courte pour le
    // calendrier : sans cela l'overflow masquerait le vrai résultat.
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // On réutilise les délégués déclarés par l'application, sans le splash
    // dont le minuteur de navigation ferait disparaître le dialogue.
    final app = await materialAppDeLApplication(tester);
    final delegates = app.localizationsDelegates!.toList();
    final locales = app.supportedLocales.toList();
    await tester.pump(const Duration(seconds: 4));

    late BuildContext contexte;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: locales,
        localizationsDelegates: delegates,
        home: Builder(
          builder: (ctx) {
            contexte = ctx;
            return const Scaffold();
          },
        ),
      ),
    );

    showDatePicker(
      context: contexte,
      initialDate: DateTime(2000, 4, 12),
      firstDate: DateTime(1920),
      lastDate: DateTime(2030),
      locale: const Locale('fr'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    // Libellé propre à la locale française : la traduction est bien chargée.
    // La casse du libellé Material a changé selon les versions de Flutter.
    expect(
      find.textContaining(RegExp('annuler', caseSensitive: false)),
      findsOneWidget,
    );
  });
}
