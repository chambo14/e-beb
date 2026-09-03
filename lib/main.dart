import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'presentation/providers/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // ProviderScope : racine de l'injection de dépendances Riverpod.
  runApp(const ProviderScope(child: EbebApp()));
}

class EbebApp extends ConsumerStatefulWidget {
  const EbebApp({super.key});

  @override
  ConsumerState<EbebApp> createState() => _EbebAppState();
}

class _EbebAppState extends ConsumerState<EbebApp> with WidgetsBindingObserver {
  // Le Navigator imbriqué du verrou reste monté en permanence une fois la
  // session authentifiée (voir `builder` ci-dessous) : cette clé permet de
  // remettre sa pile de routes à zéro à chaque nouveau verrouillage, au cas
  // où un parcours secondaire (« code PIN oublié ») serait resté ouvert d'un
  // cycle précédent.
  final _lockNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mise en arrière-plan alors que la session est toujours valide : on
    // verrouille l'application (code PIN requis, jamais d'OTP). Sans effet
    // si la session n'est pas authentifiée (voir SessionController.verrouiller).
    if (state == AppLifecycleState.paused) {
      ref.read(sessionProvider.notifier).verrouiller();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nouveau verrouillage : remet la pile du Navigator imbriqué du verrou à
    // son seul écran de base (LockScreen) — voir le commentaire détaillé
    // plus bas, près de sa déclaration. `ref.listen` doit être appelé ici,
    // directement dans `build`, et non dans le callback `builder` de
    // `MaterialApp` ci-dessous : celui-ci s'exécute plus tard, au sein d'un
    // `Builder` imbriqué distinct, hors du build de ce widget.
    ref.listen(sessionProvider, (precedent, courant) {
      if (precedent?.verrouille != true && courant.verrouille) {
        _lockNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    return MaterialApp(
      title: 'Ebeb Finance',
      debugShowCheckedModeBanner: false,
      // Sans ces délégués, tout showDatePicker(locale: Locale('fr')) échoue
      // faute de MaterialLocalizations pour le français.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.purple,
          error: AppColors.error,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textHint),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const SplashScreen(),
      builder: (context, child) {
        final session = ref.watch(sessionProvider);

        return Stack(
          children: [
            if (child != null) child,
            // Superposition plutôt que navigation : évite de perturber la
            // pile de routes en cours (Navigator) lors du verrouillage. Un
            // Navigator imbriqué dédié est néanmoins nécessaire : `builder`
            // place ce contenu au-dessus/à côté du Navigator principal (dans
            // `child`), pas en dessous, donc sans lui `Navigator.of(context)`
            // et `showDialog(...)` depuis LockScreen (ex. le parcours « code
            // PIN oublié ») ne trouveraient aucun Navigator ancêtre.
            //
            // Monté une seule fois pour toute la durée de la session
            // authentifiée (jamais démonté/recréé à chaque cycle
            // verrou/déverrou) — seule sa visibilité change, via `Offstage`.
            // Le retirer/rajouter dynamiquement à l'arbre exposait une
            // course : si `deverrouiller()` s'exécutait pendant qu'une
            // transition de route de ce Navigator était encore en vol (le
            // déverrouillage biométrique peut aboutir en quelques dizaines de
            // ms), le callback de fin de transition s'exécutait ensuite sur
            // un Navigator déjà démonté et levait `Hero: navigator != null` /
            // `Navigator: !_debugLocked` — une exception non interceptée qui
            // corrompt l'arène de gestes de Flutter et fige l'application.
            if (session.estAuthentifie)
              Positioned.fill(
                child: Offstage(
                  offstage: !session.verrouille,
                  child: Navigator(
                    key: _lockNavigatorKey,
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => const LockScreen(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
