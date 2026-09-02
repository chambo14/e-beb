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
            if (session.estAuthentifie && session.verrouille)
              Positioned.fill(
                child: Navigator(
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => const LockScreen()),
                ),
              ),
          ],
        );
      },
    );
  }
}
