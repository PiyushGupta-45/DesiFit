import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/glass.dart';
import '../widgets/weight_log_sheet.dart';
import 'history_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tab) goTo;
  const HomeScreen({super.key, required this.goTo});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = DateTime.now();
    final n = s.totalsOn(today);
    final burned = s.burnedOn(today);
    final p = s.profile;
    // Food target is based only on what was eaten. Exercise stays visible as
    // its own metric and never increases the day's food allowance.
    final remaining = p.calorieTarget - n.kcal;
    final over = remaining < 0;
    final hour = today.hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final accountName = context.watch<AuthState>().name?.trim() ?? '';
    final displayName = accountName.isNotEmpty ? accountName : p.name.trim();
    final name = displayName.isEmpty ? '' : ', ${displayName.split(' ').first}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
      children: [
        const SizedBox(height: 8),
        Text('${_days[today.weekday - 1]}, ${today.day} ${_months[today.month - 1]}',
            style: t(14, color: C.textDim)),
        const SizedBox(height: 4),
        Text('$greet$name 🙏', style: t(30, w: FontWeight.w800, h: 1.1, ls: -0.8)),
        const SizedBox(height: 16),
        _FitnessHero(name: displayName.split(' ').first),
        if (s.weightOn(today) == null) ...[
          const SizedBox(height: 14),
          Pressable(
            onTap: () async {
              final kg = await showWeightLogSheet(
                context,
                date: today,
                initialKg: s.profile.weightKg,
              );
              if (kg == null || !context.mounted) return;
              // Let the dismissed modal finish deactivating before the provider rebuild.
              await Future<void>.delayed(const Duration(milliseconds: 250));
              if (context.mounted) s.logWeight(today, kg);
            },
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              tint: C.mintGradient,
              child: Row(children: [
                const Icon(Icons.monitor_weight_outlined, size: 23),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Log today\'s weight', style: t(15, w: FontWeight.w800)),
                  Text('Keep your progress record accurate', style: t(12, color: C.textDim)),
                ])),
                Icon(Icons.add_circle_outline_rounded, color: C.mint),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // ── Hero ring
        GlassCard(
          padding: const EdgeInsets.all(22),
          child: Row(children: [
            GlowRing(
              progress: p.calorieTarget == 0 ? 0 : n.kcal / p.calorieTarget,
              size: 150,
              stroke: 15,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${remaining.abs().round()}',
                    style: t(34, w: FontWeight.w800, ls: -1,
                        color: over ? C.flame : C.text)),
                Text(over ? 'kcal over' : 'kcal left',
                    style: t(12.5, color: C.textDim)),
              ]),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _stat('🍽️', 'Eaten', '${n.kcal.round()}', 'kcal'),
                const SizedBox(height: 14),
                _stat('🔥', 'Burned', '${burned.round()}', 'kcal'),
                const SizedBox(height: 14),
                _stat('🎯', 'Target', '${p.calorieTarget}', 'kcal'),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Protein + macros
        GlassCard(
          child: Column(children: [
            Row(children: [
              Text('Protein goal', style: t(16, w: FontWeight.w700)),
              const Spacer(),
              Text(
                n.protein >= p.proteinTarget
                    ? 'Goal hit 💪'
                    : '${(p.proteinTarget - n.protein).round()} g to go',
                style: t(13, color: n.protein >= p.proteinTarget ? C.mint : C.textDim),
              ),
            ]),
            const SizedBox(height: 14),
            MacroBar(
                label: 'Protein',
                value: n.protein,
                target: p.proteinTarget.toDouble(),
                gradient: C.mintGradient),
            const SizedBox(height: 14),
            MacroBar(
                label: 'Carbs',
                value: n.carbs,
                target: (p.calorieTarget * 0.5 / 4),
                gradient: C.heroGradient),
            const SizedBox(height: 14),
            MacroBar(
                label: 'Fat',
                value: n.fat,
                target: (p.calorieTarget * 0.28 / 9),
                gradient: C.violetGradient),
          ]),
        ),

        // ── Meals today
        SectionTitle('Today\'s meals',
            trailing: _link('Add food', () => goTo(1))),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(children: [
            for (final m in MealType.values) _mealRow(s, m, today),
          ]),
        ),

        // ── Workout
        SectionTitle('Workout', trailing: _link('Log', () => goTo(2))),
        _workoutCard(s, today, p),

        // ── Week chart
        SectionTitle(
          'Last 7 days',
          trailing: Text('Tap for history', style: t(12, color: C.textDim)),
        ),
        Pressable(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HistoryDashboardScreen()),
          ),
          child: _weekCard(s, p),
        ),
      ],
    );
  }

  Widget _stat(String emoji, String label, String v, String unit) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t(12, color: C.textDim)),
          Text.rich(TextSpan(children: [
            TextSpan(text: v, style: t(19, w: FontWeight.w800)),
            TextSpan(text: ' $unit', style: t(12, color: C.textDim)),
          ])),
        ]),
      ]);

  Widget _link(String text, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(text, style: t(13, w: FontWeight.w600)),
        ),
      );

  Widget _mealRow(AppState s, MealType m, DateTime d) {
    final items = s.dietOn(d).where((e) => e.meal == m).toList();
    final kcal = items.fold(0.0, (a, e) => a + e.n.kcal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Text(m.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, style: t(15, w: FontWeight.w700)),
            Text(
              items.isEmpty ? 'Nothing logged' : items.map((e) => e.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t(12.5, color: C.textFaint),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text(items.isEmpty ? '–' : '${kcal.round()} kcal',
            style: t(14, w: FontWeight.w700)),
      ]),
    );
  }

  Widget _workoutCard(AppState s, DateTime d, Profile p) {
    final list = s.workoutsOn(d);
    final burned = s.burnedOn(d);
    return GlassCard(
      child: Row(children: [
        GlowRing(
          progress: p.burnTarget == 0 ? 0 : burned / p.burnTarget,
          size: 76,
          stroke: 9,
          gradient: C.mintGradient,
          child: const Text('🔥', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: list.isEmpty
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('No workout yet', style: t(16, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Target ${p.burnTarget} kcal burn today',
                      style: t(13, color: C.textDim)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${burned.round()} / ${p.burnTarget} kcal',
                      style: t(18, w: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final w in list.take(3))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${w.done ? '✅' : '⏭️'} ${w.name}'
                        '${w.done ? ' · ${w.minutes} min' : ' · skipped'}',
                        style: t(13, color: C.textDim),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }

  Widget _weekCard(AppState s, Profile p) {
    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));
    final vals = days.map((d) => s.totalsOn(d).kcal).toList();
    final maxV = [
      ...vals,
      p.calorieTarget * 1.15,
    ].reduce((a, b) => a > b ? a : b);
    const h = 76.0;
    const wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final targetY = p.calorieTarget / maxV * h;

    return GlassCard(
      child: Column(children: [
        SizedBox(
          height: h + 4,
          child: Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: targetY,
              child: Container(
                  height: 1.2, color: C.saffron.withValues(alpha: 0.55)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                for (var i = 0; i < 7; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: vals[i] / maxV * h),
                    duration: Duration(milliseconds: 600 + i * 90),
                    curve: Curves.easeOutBack,
                    builder: (context, v, _) => Container(
                      width: 26,
                      height: v < 0 ? 0 : v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: vals[i] > p.calorieTarget
                              ? [C.flame, C.magenta]
                              : [C.mint, C.sky],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < 7; i++)
              SizedBox(
                width: 26,
                child: Text(wd[days[i].weekday - 1],
                    textAlign: TextAlign.center,
                    style: t(12,
                        color: i == 6 ? C.text : C.textFaint,
                        w: i == 6 ? FontWeight.w800 : FontWeight.w500)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 14, height: 2, color: C.saffron),
          const SizedBox(width: 8),
          Text('Daily target ${p.calorieTarget} kcal',
              style: t(12, color: C.textDim)),
        ]),
      ]),
    );
  }
}

class _FitnessHero extends StatelessWidget {
  final String name;
  const _FitnessHero({required this.name});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          C.violet.withValues(alpha: 0.76),
          C.sky.withValues(alpha: 0.46),
          C.mint.withValues(alpha: 0.36),
        ],
      ),
      child: SizedBox(
        height: 142,
        child: Stack(children: [
          Positioned(
            right: -16,
            top: -38,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: -15,
            child: Icon(Icons.fitness_center_rounded,
                size: 146, color: Colors.white.withValues(alpha: 0.22)),
          ),
          Positioned(
            right: 37,
            top: 22,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: C.heroGradient,
                border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
                boxShadow: [
                  BoxShadow(
                      color: C.magenta.withValues(alpha: 0.38), blurRadius: 22),
                ],
              ),
              child: const Icon(Icons.directions_run_rounded,
                  color: Colors.white, size: 35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 112, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOUR DAILY RESET',
                  style: t(10,
                      w: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.78),
                      ls: 1.1)),
              const SizedBox(height: 8),
              Text(name.isEmpty ? 'Small steps.\nStrong results.' : 'Let\'s move,\n$name!',
                  style: t(21,
                      w: FontWeight.w900,
                      color: Colors.white,
                      h: 1.05)),
              const Spacer(),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: C.saffron),
                const SizedBox(width: 5),
                Text('Keep your streak alive',
                    style: t(11.5, w: FontWeight.w600, color: Colors.white)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
