import 'package:e_beb_app/core/providers/core_providers.dart';
import 'package:e_beb_app/features/auth/screens/splash_screen.dart';
import 'package:e_beb_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/token_storage_memoire.dart';

void main() {
  testWidgets('L\'application démarre sur le splash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Sans jeton persisté, la session part sur « non authentifié » et
        // aucun appel réseau protégé n'est déclenché.
        overrides: [
          tokenStorageProvider.overrideWithValue(TokenStorageMemoire()),
        ],
        child: const EbebApp(),
      ),
    );

    expect(find.byType(EbebApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Laisse retomber les animations et le timer de redirection du splash.
    await tester.pump(const Duration(seconds: 4));
  });
}
