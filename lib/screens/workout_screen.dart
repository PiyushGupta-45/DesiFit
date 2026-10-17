import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/exercises.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/glass.dart';
import '../widgets/nav.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = s.selectedDate;
    final list = s.workoutsOn(d);
    final burned = s.burnedOn(d);
    final mins = list.where((w) => w.done).fold(0, (a, w) => a + w.minutes);
    final p = s.profile;
    final isToday = sameDay(d, DateTime.now());

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Workouts', style: t(30, w: FontWeight.w800, ls: -0.8)),
                Text(isToday ? 'Today' : '${d.day}/${d.month}/${d.year}',
                    style: t(14, color: C.textDim)),
              ]),
            ),
            LiquidButton(
              label: 'Log',
              icon: Icons.add_rounded,
              compact: true,
              gradient: C.mintGradient,
              onTap: () =>
                  showGlassSheet(context, (_) => const AddWorkoutSheet()),
            ),
          ]),
        ),
        const DateStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: GlassCard(
            child: Row(children: [
              GlowRing(
                progress: p.burnTarget == 0 ? 0 : burned / p.burnTarget,
                size: 112,
                stroke: 12,
                gradient: C.mintGradient,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${burned.round()}',
                      style: t(26, w: FontWeight.w800, ls: -0.8)),
                  Text('kcal burned', style: t(11, color: C.textDim)),
                ]),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Burn target', style: t(12.5, color: C.textDim)),
                  Text('${p.burnTarget} kcal',
                      style: t(20, w: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('Active time', style: t(12.5, color: C.textDim)),
                  Text('$mins min', style: t(20, w: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('This week'),
            _weekDots(s),
            SectionTitle(isToday ? 'Today\'s log' : 'Log',
                trailing: LiquidButton(
                  label: 'Add exercise',
                  icon: Icons.add_rounded,
                  compact: true,
                  gradient: C.mintGradient,
                  onTap: () => showGlassSheet(
                      context, (_) => const AddWorkoutSheet()),
                )),
            if (list.isEmpty)
              GlassCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(children: [
                    const Text('🧘', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: 8),
                    Text('Nothing logged yet',
                        style: t(16, w: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Log what you did — or that you skipped.',
                        style: t(13, color: C.textDim)),
                  ]),
                ),
              )
            else
              for (final w in list) _tile(context, w),
          ]),
        ),
      ],
    );
  }

  Widget _weekDots(AppState s) {
    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));
    const wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final d in days)
            Builder(builder: (context) {
              final ws = s.workoutsOn(d);
              final did = ws.any((w) => w.done);
              final skipped = !did && ws.isNotEmpty;
              return Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: did ? C.mintGradient : null,
                    color: did
                        ? null
                        : skipped
                            ? C.flame.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: did ? 0.5 : 0.15)),
                  ),
                  child: Icon(
                    did
                        ? Icons.check_rounded
                        : skipped
                            ? Icons.close_rounded
                            : null,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(wd[d.weekday - 1],
                    style: t(12,
                        color: sameDay(d, today) ? C.text : C.textFaint,
                        w: sameDay(d, today) ? FontWeight.w800 : FontWeight.w500)),
              ]);
            }),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WorkoutEntry w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(w.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<AppState>().removeWorkout(w.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: C.flame.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: GlassCard(
          radius: 24,
          blur: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Text(w.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.name, style: t(16, w: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  w.done
                      ? '${w.minutes} min · ${w.intensity}'
                      : 'Skipped${w.note.isEmpty ? '' : ' · ${w.note}'}',
                  style: t(12.5, color: w.done ? C.textDim : C.flame),
                ),
              ]),
            ),
            if (w.done)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${w.kcal.round()}',
                    style: t(22, w: FontWeight.w800, color: C.mint)),
                Text('kcal', style: t(11.5, color: C.textDim)),
              ])
            else
              Icon(Icons.hotel_rounded, color: C.textFaint),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────

class AddWorkoutSheet extends StatefulWidget {
  const AddWorkoutSheet({super.key});

  @override
  State<AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<AddWorkoutSheet> {
  final List<Exercise> selectedExercises = [];
  final Set<String> selectedCategories = {};
  int minutes = 30;
  String intensity = 'Moderate';
  bool done = true;
  String reason = 'Rest day';
  String exerciseQuery = '';
  bool useSets = false;
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');

  static const reasons = ['Rest day', 'No time', 'Tired', 'Sick', 'Travelling'];

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weight = context.read<AppState>().profile.weightKg;
    final sets = int.tryParse(_sets.text) ?? 3;
    final reps = int.tryParse(_reps.text) ?? 10;
    // Each set estimates work time (5 sec/rep) plus a 75 sec rest interval.
    // In set mode this replaces the manual duration slider.
    final setMinutesPerExercise =
        (sets.clamp(1, 30) * (reps.clamp(1, 100) * 5 + 75)) / 60;
    final totalMinutes = useSets
        ? setMinutesPerExercise * selectedExercises.length
        : minutes.toDouble();
    final minutesPerExercise = selectedExercises.isEmpty
        ? 0.0
        : totalMinutes / selectedExercises.length;
    final kcal = selectedExercises.fold(
        0.0,
        (total, exercise) =>
            total +
            caloriesBurned(
                met: exercise.met,
                weightKg: weight,
                minutes: minutesPerExercise,
                intensity: intensity));
    final shownExercises = exercises
        .where((e) =>
            (selectedCategories.isEmpty ||
                selectedCategories.contains(e.category)) &&
            e.name.toLowerCase().contains(exerciseQuery.trim().toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log workout', style: t(22, w: FontWeight.w800)),
        const SizedBox(height: 14),

        // did / skipped toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Expanded(child: _seg('✅  I did it', done, () => setState(() => done = true))),
            Expanded(child: _seg('⏭️  Skipped', !done, () => setState(() => done = false))),
          ]),
        ),
        const SizedBox(height: 18),

        if (done) ...[
          Text('What did you train today?', style: t(15, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Select one or more muscle groups, then choose exercises.',
              style: t(12, color: C.textDim)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final category in exerciseCategories)
              GlassChip(
                label: category,
                selected: selectedCategories.contains(category),
                activeGradient: C.mintGradient,
                onTap: () => setState(() {
                  if (!selectedCategories.add(category)) {
                    selectedCategories.remove(category);
                  }
                }),
              ),
          ]),
          const SizedBox(height: 14),
          GlassField(
            hint: 'Search bicep, bench, squat, cardio...',
            icon: Icons.search_rounded,
            onChanged: (value) => setState(() => exerciseQuery = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: shownExercises.isEmpty
                ? Center(
                    child: Text('No exercise found', style: t(14, color: C.textDim)))
                : ListView.separated(
                    itemCount: shownExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = shownExercises[index];
                      final selected = selectedExercises.contains(e);
                      return Pressable(
                        onTap: () => setState(() {
                          if (!selectedExercises.remove(e)) {
                            selectedExercises.add(e);
                          }
                        }),
                        scale: 0.98,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: selected ? C.mintGradient : null,
                            color: selected ? null : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: selected ? 0.45 : 0.12)),
                          ),
                          child: Row(children: [
                            Text(e.emoji, style: const TextStyle(fontSize: 21)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: t(14, w: FontWeight.w700)),
                                  Text(e.category,
                                      style: t(11,
                                          color: selected ? Colors.white : C.textDim)),
                                ],
                              ),
                            ),
                            Text('MET ${e.met}', style: t(12, color: selected ? Colors.white : C.textDim)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          if (selectedExercises.isNotEmpty) ...[
            Text('${selectedExercises.length} exercise${selectedExercises.length == 1 ? '' : 's'} selected',
                style: t(13, color: C.mint, w: FontWeight.w700)),
            const SizedBox(height: 8),
          ],
          Row(children: [
            GlassChip(
              label: 'Duration',
              selected: !useSets,
              activeGradient: C.mintGradient,
              onTap: () => setState(() => useSets = false),
            ),
            const SizedBox(width: 8),
            GlassChip(
              label: 'Sets & reps',
              selected: useSets,
              activeGradient: C.mintGradient,
              onTap: () => setState(() => useSets = true),
            ),
          ]),
          const SizedBox(height: 14),
          if (!useSets) ...[
            Row(children: [
              Text('Duration', style: t(15, w: FontWeight.w700)),
              const Spacer(),
              Text('$minutes min', style: t(15, w: FontWeight.w800)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: C.mint,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                thumbColor: Colors.white,
                overlayColor: C.mint.withValues(alpha: 0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: minutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                onChanged: (v) => setState(() => minutes = v.round()),
              ),
            ),
          ] else ...[
            Row(children: [
              Expanded(
                child: GlassField(
                  controller: _sets,
                  hint: 'Sets',
                  suffix: 'sets',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassField(
                  controller: _reps,
                  hint: 'Reps',
                  suffix: 'reps',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text('Estimated ${totalMinutes.round()} min including rest',
                style: t(12, color: C.textDim)),
          ],
          const SizedBox(height: 6),
          Text('Intensity', style: t(15, w: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final i in intensities.keys)
              GlassChip(
                label: i,
                selected: intensity == i,
                onTap: () => setState(() => intensity = i),
              ),
          ]),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(selectedExercises.isEmpty
                          ? 'Select exercises first'
                          : '${kcal.round()} kcal burned',
                      style: t(22, w: FontWeight.w800, color: C.mint)),
                  Text(
                      selectedExercises.isEmpty
                          ? 'Your weight, duration and intensity will be used.'
                          : useSets
                              ? '$sets sets × $reps reps · ${totalMinutes.round()} min estimated'
                              : '${selectedExercises.length} exercises share $minutes min · weight-adjusted estimate',
                      style: t(12, color: C.textDim)),
                ]),
              ),
            ]),
          ),
        ] else ...[
          Text('What happened?', style: t(15, w: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in reasons)
              GlassChip(
                label: r,
                selected: reason == r,
                activeGradient: LinearGradient(colors: [C.flame, C.magenta]),
                onTap: () => setState(() => reason = r),
              ),
          ]),
        ],
        const SizedBox(height: 24),
        Center(
          child: LiquidButton(
            label: done ? 'Save workout' : 'Save as skipped',
            icon: Icons.check_rounded,
            gradient: done ? C.mintGradient : C.heroGradient,
            onTap: done && selectedExercises.isEmpty
                ? null
                : () {
              final s = context.read<AppState>();
              final d = s.selectedDate;
              final now = DateTime.now();
              if (done) {
                for (var index = 0; index < selectedExercises.length; index++) {
                  final exercise = selectedExercises[index];
                  final exerciseMinutes = useSets
                      ? setMinutesPerExercise.round()
                      : minutes ~/ selectedExercises.length +
                          (index < minutes % selectedExercises.length ? 1 : 0);
                  s.addWorkout(WorkoutEntry(
                    id: '${now.microsecondsSinceEpoch}-$index',
                    time: DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second),
                    name: exercise.name,
                    emoji: exercise.emoji,
                    minutes: exerciseMinutes,
                    intensity: intensity,
                    done: true,
                    kcal: caloriesBurned(
                        met: exercise.met,
                        weightKg: weight,
                        minutes: exerciseMinutes.toDouble(),
                        intensity: intensity),
                  ));
                }
              } else {
                s.addWorkout(WorkoutEntry(
                  id: '${now.microsecondsSinceEpoch}',
                  time: DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second),
                  name: 'Workout skipped',
                  emoji: '⏭️',
                  minutes: 0,
                  intensity: intensity,
                  done: false,
                  kcal: 0,
                  note: reason,
                ));
              }
              Navigator.pop(context);
            },
          ),
        ),
      ]),
    );
  }

  Widget _seg(String label, bool sel, VoidCallback onTap) => Pressable(
        onTap: onTap,
        scale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: sel
                ? LinearGradient(colors: [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.14),
                  ])
                : null,
            border: sel
                ? Border.all(color: Colors.white.withValues(alpha: 0.5))
                : null,
          ),
          child: Text(label,
              style: t(14.5,
                  w: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? Colors.white : C.textDim)),
        ),
      );
}
