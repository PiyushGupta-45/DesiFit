import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'auth/auth_state.dart';
import 'data/foods.dart';
import 'screens/auth_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/weight_records_screen.dart';
import 'screens/workout_screen.dart';
import 'state.dart';
import 'widgets/glass.dart';
import 'widgets/app_update_prompt.dart';
import 'widgets/nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'config/app.env');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  final state = AppState();
  await state.load();
  final auth = AuthState();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: state),
      ChangeNotifierProvider.value(value: auth),
    ],
    child: const DesiFitApp(),
  ));
  // Start network work only after Flutter has been handed its first frame.
  // The splash must never wait for a slow/offline backend or Render cold start.
  unawaited(auth.initialize());
}

class DesiFitApp extends StatelessWidget {
  const DesiFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightMode = context.select<AppState, bool>((state) => state.lightMode);
    C.setLight(lightMode);
    final brightness = lightMode ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: lightMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: C.bg1,
      systemNavigationBarIconBrightness:
          lightMode ? Brightness.dark : Brightness.light,
    ));
    return MaterialApp(
      title: 'DesiFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        scaffoldBackgroundColor: C.bg1,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.violet,
          brightness: brightness,
        ).copyWith(primary: C.violet, secondary: C.mint, surface: C.bg2),
        splashFactory: NoSplash.splashFactory,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _SplashScreen();
    final signedIn = context.select<AuthState, bool>((auth) => auth.signedIn);
    if (!signedIn) return const AuthScreen();
    return _CloudSession(key: ValueKey(context.read<AuthState>().email));
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg1,
      body: AuroraBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 760),
            curve: Curves.easeOutBack,
            builder: (context, scale, _) => Transform.scale(
              scale: scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: C.heroGradient,
                    boxShadow: [
                      BoxShadow(
                        color: C.magenta.withValues(alpha: 0.42),
                        blurRadius: 34,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      size: 52, color: Colors.white),
                ),
                const SizedBox(height: 22),
                Text('DesiFit', style: t(34, w: FontWeight.w900, ls: -1.2)),
                const SizedBox(height: 6),
                Text('Eat better. Move stronger.',
                    style: t(14, color: C.textDim)),
                const SizedBox(height: 28),
                SizedBox(
                  width: 112,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(99),
                    color: C.mint,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudSession extends StatefulWidget {
  const _CloudSession({super.key});

  @override
  State<_CloudSession> createState() => _CloudSessionState();
}

class _CloudSessionState extends State<_CloudSession> {
  Timer? _uploadTimer;
  bool _readyToUpload = false;
  // A person can start using the app before the first cloud download finishes.
  // Keep their changes (especially a just-added daily weight) from being
  // overwritten by an older server snapshot that arrives a moment later.
  bool _initialSyncInProgress = true;
  bool _localChangedDuringInitialSync = false;
  bool _catalogFetching = false;
  bool _catalogFetched = false;
  late final AppState _app;
  late final AuthState _auth;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _auth = context.read<AuthState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    _app.addListener(_queueUpload);
    _auth.addListener(_refreshCatalogueWhenOnline);
  }

  @override
  void dispose() {
    _app.removeListener(_queueUpload);
    _auth.removeListener(_refreshCatalogueWhenOnline);
    _uploadTimer?.cancel();
    super.dispose();
  }

  Future<void> _sync() async {
    _refreshCatalogueWhenOnline();
    final remote = await _auth.downloadCloudData();
    if (mounted && remote != null) {
      final hasCloudData =
          (remote['profile'] is Map && (remote['profile'] as Map).isNotEmpty) ||
              ((remote['diet'] as List?)?.isNotEmpty ?? false) ||
              ((remote['workouts'] as List?)?.isNotEmpty ?? false) ||
              ((remote['weightLogs'] as List?)?.isNotEmpty ?? false) ||
              ((remote['customFoods'] as List?)?.isNotEmpty ?? false) ||
              ((remote['reminders'] as List?)?.isNotEmpty ?? false);
      if (_localChangedDuringInitialSync) {
        // The device has newer data than the snapshot we requested at launch.
        // Upload it instead of replacing it with that stale snapshot.
        await _auth.uploadCloudData(_app.cloudSnapshot());
      } else if (hasCloudData) {
        // Initial sync is a merge, not a replacement. A stale cloud document
        // must never make today's weight or locally-created alerts disappear.
        await _app.applyCloudSnapshot(remote, preserveLocal: true);
        await _auth.uploadCloudData(_app.cloudSnapshot());
        // Applying the downloaded snapshot notifies AppState listeners; it is
        // not a user edit and must not be treated as one.
        _localChangedDuringInitialSync = false;
      } else {
        await _auth.uploadCloudData(_app.cloudSnapshot());
      }
    }
    if (!mounted) return;
    _initialSyncInProgress = false;
    _readyToUpload = true;
    if (_localChangedDuringInitialSync) _queueUpload();
  }

  void _refreshCatalogueWhenOnline() {
    if (!_auth.backendOnline || _catalogFetching || _catalogFetched) return;
    unawaited(_downloadCatalogue());
  }

  Future<void> _downloadCatalogue() async {
    _catalogFetching = true;
    final foods = await _auth.downloadFoodCatalog();
    if (mounted && foods != null) {
      await _app.replaceCatalogFoods(foods.map(FoodItem.fromCatalogJson).toList());
      _catalogFetched = true;
    }
    _catalogFetching = false;
  }

  void _queueUpload() {
    if (!_readyToUpload) {
      if (_initialSyncInProgress) _localChangedDuringInitialSync = true;
      return;
    }
    _uploadTimer?.cancel();
    _uploadTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _auth.uploadCloudData(_app.cloudSnapshot());
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppState, bool>((s) => s.onboarded);
    return Scaffold(
      backgroundColor: C.bg1,
      body: AuroraBackground(
        child: AppUpdatePrompt(
          child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          child: onboarded
              ? const Shell(key: ValueKey('shell'))
              : _Welcome(key: const ValueKey('welcome')),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    // GoalsScreen persists the profile on "Start tracking", which flips
    // AppState.onboarded and swaps this screen for the Shell.
    return const SafeArea(child: GoalsScreen(onboarding: true));
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  static const items = [
    NavItem(Icons.grid_view_rounded, 'Today'),
    NavItem(Icons.restaurant_rounded, 'Diet'),
    NavItem(Icons.fitness_center_rounded, 'Workout'),
    NavItem(Icons.monitor_weight_outlined, 'Weight'),
    NavItem(Icons.notifications_active_rounded, 'Alerts'),
    NavItem(Icons.tune_rounded, 'Goals'),
  ];

  void go(int i) {
    // Diet / Workout tabs show the selected day; jump back to today when
    // arriving from a shortcut on Home.
    if (i == 1 || i == 2) context.read<AppState>().selectDate(DateTime.now());
    setState(() => tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(goTo: go),
      const DietScreen(),
      const WorkoutScreen(),
      const WeightRecordsScreen(embedded: true),
      const RemindersScreen(),
      const GoalsScreen(),
    ];
    return Stack(children: [
      SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(tab), child: screens[tab]),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: LiquidNavBar(index: tab, items: items, onChanged: go),
      ),
    ]);
  }
}
