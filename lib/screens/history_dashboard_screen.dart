import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets/glass.dart';

class HistoryDashboardScreen extends StatefulWidget {
  const HistoryDashboardScreen({super.key});

  @override
  State<HistoryDashboardScreen> createState() => _HistoryDashboardScreenState();
}

class _HistoryDashboardScreenState extends State<HistoryDashboardScreen> {
  DateTime _selected = DateTime.now();
  bool _editingWeight = false;
  final _weightController = TextEditingController();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nutrition = state.totalsOn(_selected);
    final foods = state.dietOn(_selected);
    final workouts = state.workoutsOn(_selected);
    final burned = state.burnedOn(_selected);
    final weight = state.weightOn(_selected);
    final net = nutrition.kcal - burned;

    return Scaffold(
      backgroundColor: C.bg1,
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Row(children: [
                Pressable(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 21),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('History dashboard', style: t(28, w: FontWeight.w800, ls: -0.8)),
                    Text('Food, calories, workouts and weight',
                        style: t(13, color: C.textDim)),
                  ]),
                ),
                Pressable(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 21),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _dateStrip(),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(children: [
                  Text(_dateTitle(_selected), style: t(17, w: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _summary('Eaten', '${nutrition.kcal.round()}', 'kcal', C.saffron),
                    _summary('Burned', '${burned.round()}', 'kcal', C.mint),
                    _summary('Net', '${net.round()}', 'kcal', net > state.profile.calorieTarget ? C.flame : C.sky),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    _macro('Protein', '${nutrition.protein.round()} g', C.mint),
                    _macro('Carbs', '${nutrition.carbs.round()} g', C.saffron),
                    _macro('Fat', '${nutrition.fat.round()} g', C.magenta),
                  ]),
                ]),
              ),
              SectionTitle('Weight log', trailing: _weightAction(weight)),
              if (_editingWeight) ...[
                _inlineWeightEditor(state),
                const SizedBox(height: 10),
              ],
              _weightCard(state, weight),
              SectionTitle('Food log', trailing: Text('${foods.length} items', style: t(13, color: C.textDim))),
              if (foods.isEmpty)
                _emptyCard(Icons.restaurant_outlined, 'No food logged on this day')
              else
                for (final meal in MealType.values) ...[
                  if (foods.any((entry) => entry.meal == meal))
                    _mealCard(meal, foods.where((entry) => entry.meal == meal).toList()),
                  if (foods.any((entry) => entry.meal == meal)) const SizedBox(height: 10),
                ],
              SectionTitle('Workout log', trailing: Text('${burned.round()} kcal burned', style: t(13, color: C.mint))),
              if (workouts.isEmpty)
                _emptyCard(Icons.fitness_center_outlined, 'No workout logged on this day')
              else
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(children: [
                    for (final workout in workouts) _workoutRow(workout),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateStrip() {
    final start = DateTime(_selected.year, _selected.month, _selected.day - 3);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Pressable(
              onTap: () => setState(() {
                _selected = start.add(Duration(days: i));
                _editingWeight = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: sameDay(_selected, start.add(Duration(days: i))) ? C.heroGradient : null,
                ),
                child: Column(children: [
                  Text(_weekdays[start.add(Duration(days: i)).weekday - 1].substring(0, 1),
                      style: t(11, color: C.textDim)),
                  const SizedBox(height: 3),
                  Text('${start.add(Duration(days: i)).day}', style: t(17, w: FontWeight.w800)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _summary(String label, String value, String unit, Color color) => Expanded(
        child: Column(children: [
          Text(value, style: t(21, w: FontWeight.w800, color: color)),
          Text(unit, style: t(11, color: C.textDim)),
          const SizedBox(height: 3),
          Text(label, style: t(12, color: C.textFaint)),
        ]),
      );

  Widget _macro(String label, String value, Color color) => Expanded(
        child: Column(children: [
          Text(value, style: t(15, w: FontWeight.w800, color: color)),
          Text(label, style: t(11, color: C.textDim)),
        ]),
      );

  Widget _weightAction(WeightEntry? weight) => Pressable(
          onTap: () {
            final existing = context.read<AppState>().weightOn(_selected);
            setState(() {
              _weightController.text =
                  (existing?.kg ?? context.read<AppState>().profile.weightKg).toStringAsFixed(1);
              _editingWeight = true;
            });
          },
          child: Text(weight == null ? '+ Add weight' : 'Edit',
              style: t(13, w: FontWeight.w700, color: C.mint)),
        );

  Widget _inlineWeightEditor(AppState state) => GlassCard(
        tint: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15424A), Color(0xFF223160), Color(0xFF522352)],
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.monitor_weight_outlined, color: C.mint),
            const SizedBox(width: 10),
            Expanded(child: Text('Weight for ${_dateTitle(_selected)}', style: t(15, w: FontWeight.w800))),
            IconButton(
              onPressed: () => setState(() => _editingWeight = false),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel',
            ),
          ]),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: t(27, w: FontWeight.w800),
                decoration: InputDecoration(
                  suffixText: 'kg',
                  suffixStyle: t(15, color: C.textDim),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _saveWeight(state),
              ),
            ),
            LiquidButton(
              label: 'Save',
              compact: true,
              icon: Icons.check_rounded,
              onTap: () => _saveWeight(state),
            ),
          ]),
        ]),
      );

  void _saveWeight(AppState state) {
    final kg = double.tryParse(_weightController.text.trim());
    if (kg == null || kg < 20 || kg > 300) return;
    state.logWeight(_selected, kg);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editingWeight = false);
  }

  Widget _weightCard(AppState state, WeightEntry? selectedWeight) {
    final logs = state.weightLogs.reversed.take(7).toList().reversed.toList();
    final latest = selectedWeight?.kg ?? state.profile.weightKg;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.monitor_weight_outlined, color: C.mint),
          const SizedBox(width: 10),
          Text('${latest.toStringAsFixed(1)} kg', style: t(25, w: FontWeight.w800)),
          const Spacer(),
          Text(selectedWeight == null ? 'No entry for this day' : 'Logged', style: t(12, color: C.textDim)),
        ]),
        if (logs.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final log in logs)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: _weightBarHeight(logs, log.kg),
                            decoration: BoxDecoration(
                              gradient: C.mintGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${log.date.day}', style: t(10, color: C.textDim)),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  double _weightBarHeight(List<WeightEntry> logs, double kg) {
    final values = logs.map((entry) => entry.kg);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max == min) return 28;
    return 16 + ((kg - min) / (max - min) * 28);
  }

  Widget _mealCard(MealType meal, List<DietEntry> entries) {
    final total = entries.fold(0.0, (sum, entry) => sum + entry.n.kcal);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(children: [
        Row(children: [
          Text(meal.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 9),
          Text(meal.label, style: t(15, w: FontWeight.w800)),
          const Spacer(),
          Text('${total.round()} kcal', style: t(14, w: FontWeight.w700, color: C.saffron)),
        ]),
        const Divider(height: 18, color: Colors.white12),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.name, style: t(14, w: FontWeight.w700)),
                Text('${entry.detail} · ${_time(entry.time)}', style: t(11.5, color: C.textDim)),
              ])),
              Text('${entry.n.kcal.round()} kcal', style: t(13, w: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }

  Widget _workoutRow(WorkoutEntry workout) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(workout.emoji, style: const TextStyle(fontSize: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(workout.name, style: t(14, w: FontWeight.w700)),
            Text('${workout.minutes} min · ${workout.intensity} · ${_time(workout.time)}',
                style: t(11.5, color: C.textDim)),
          ])),
          Text(workout.done ? '${workout.kcal.round()} kcal' : 'Skipped',
              style: t(13, w: FontWeight.w700, color: workout.done ? C.mint : C.textDim)),
        ]),
      );

  Widget _emptyCard(IconData icon, String text) => GlassCard(
        child: Row(children: [
          Icon(icon, color: C.textDim),
          const SizedBox(width: 12),
          Text(text, style: t(14, color: C.textDim)),
        ]),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  String _dateTitle(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

  String _time(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
