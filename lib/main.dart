import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/diet_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/workout_screen.dart';
import 'state.dart';
import 'widgets/glass.dart';
import 'widgets/nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  final state = AppState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const DesiFitApp()));
}

class DesiFitApp extends StatelessWidget {
  const DesiFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesiFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg1,
        colorScheme: const ColorScheme.dark(
          primary: C.saffron,
          secondary: C.mint,
          surface: C.bg2,
        ),
        splashFactory: NoSplash.splashFactory,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const Root(),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppState, bool>((s) => s.onboarded);
    return Scaffold(
      backgroundColor: C.bg1,
      body: AuroraBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          child: onboarded
              ? const Shell(key: ValueKey('shell'))
              : _Welcome(key: const ValueKey('welcome')),
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
