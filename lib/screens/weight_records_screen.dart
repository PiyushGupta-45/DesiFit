import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets/glass.dart';

class WeightRecordsScreen extends StatefulWidget {
  const WeightRecordsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WeightRecordsScreen> createState() => _WeightRecordsScreenState();
}

class _WeightRecordsScreenState extends State<WeightRecordsScreen> {
  bool _monthly = false;
  bool _editing = false;
  DateTime _anchor = DateTime.now();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final range = _rangeFor(_anchor);
    final records = state.weightLogs
        .where((entry) => !entry.date.isBefore(range.start) && entry.date.isBefore(range.end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final previousRange = _previousRange(range);
    final previous = state.weightLogs
        .where((entry) => !entry.date.isBefore(previousRange.start) && entry.date.isBefore(previousRange.end))
        .toList();
    final average = _average(records);
    final previousAverage = _average(previous);
    final delta = average == null || previousAverage == null ? null : average - previousAverage;

    return WillPopScope(
      onWillPop: () async {
        if (!_editing) return true;
        setState(() => _editing = false);
        return false;
      },
      child: Scaffold(
        backgroundColor: C.bg1,
        body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, widget.embedded ? 116 : 32),
            children: [
              Row(children: [
                if (!widget.embedded) ...[
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 21),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Weight records', style: t(28, w: FontWeight.w800, ls: -0.8)),
                  Text('Track your weekly progress', style: t(13, color: C.textDim)),
                ])),
                Pressable(
                  onTap: () {
                    final state = context.read<AppState>();
                    final today = DateTime.now();
                    final existing = state.weightOn(today);
                    setState(() {
                      _weightController.text =
                          (existing?.kg ?? state.profile.weightKg).toStringAsFixed(1);
                      _editing = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: C.mintGradient),
                    child: const Icon(Icons.add_rounded, size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              if (_editing) ...[
                _inlineEditor(state),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Expanded(child: GlassChip(label: 'Weekly', selected: !_monthly, activeGradient: C.mintGradient, onTap: () => setState(() => _monthly = false))),
                const SizedBox(width: 10),
                Expanded(child: GlassChip(label: 'Monthly', selected: _monthly, activeGradient: C.violetGradient, onTap: () => setState(() => _monthly = true))),
              ]),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(children: [
                  IconButton(onPressed: () => setState(() => _shift(-1)), icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(child: Text(_rangeTitle(range), textAlign: TextAlign.center, style: t(16, w: FontWeight.w800))),
                  IconButton(
                    onPressed: range.end.isAfter(DateTime.now().add(const Duration(days: 1))) ? null : () => setState(() => _shift(1)),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              GlassCard(
                tint: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF193B59), Color(0xFF281647), Color(0xFF4B1D47)],
                ),
                child: Column(children: [
                  Text(average == null ? '--' : '${average.toStringAsFixed(1)} kg', style: t(36, w: FontWeight.w800, color: C.mint)),
                  Text('average ${_monthly ? 'this month' : 'this week'}', style: t(13, color: C.textDim)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _comparison('Entries', '${records.length}', C.sky),
                    _comparison('Previous avg', previousAverage == null ? '--' : '${previousAverage.toStringAsFixed(1)} kg', C.textDim),
                    _comparison(
                      delta == null ? 'Change' : delta == 0 ? 'No change' : delta < 0 ? 'Lost' : 'Gained',
                      delta == null ? '--' : '${delta.abs().toStringAsFixed(1)} kg',
                      delta == null ? C.textDim : delta <= 0 ? C.mint : C.flame,
                    ),
                  ]),
                ]),
              ),
              SectionTitle(_monthly ? 'Daily entries' : 'This week'),
              if (records.isEmpty)
                GlassCard(child: Text('No weight entries in this period.', style: t(14, color: C.textDim)))
              else ...[
                _chart(records),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(children: [for (final record in records) _recordRow(record)]),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _inlineEditor(AppState state) => GlassCard(
        tint: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15424A), Color(0xFF223160), Color(0xFF522352)],
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.monitor_weight_outlined, color: C.mint),
            const SizedBox(width: 10),
            Text('Log today\'s weight', style: t(16, w: FontWeight.w800)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _editing = false),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel',
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: t(30, w: FontWeight.w800),
            decoration: InputDecoration(
              suffixText: 'kg',
              suffixStyle: t(15, color: C.textDim),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _saveInlineWeight(state),
          ),
          const SizedBox(height: 10),
          LiquidButton(
            label: 'Save weight',
            icon: Icons.check_rounded,
            onTap: () => _saveInlineWeight(state),
          ),
        ]),
      );

  void _saveInlineWeight(AppState state) {
    final kg = double.tryParse(_weightController.text.trim());
    if (kg == null || kg < 20 || kg > 300) return;
    state.logWeight(DateTime.now(), kg);
    setState(() => _editing = false);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _comparison(String label, String value, Color color) => Expanded(
        child: Column(children: [
          Text(value, style: t(16, w: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: t(11, color: C.textDim)),
        ]),
      );

  Widget _chart(List<WeightEntry> records) {
    final min = records.map((entry) => entry.kg).reduce((a, b) => a < b ? a : b);
    final max = records.map((entry) => entry.kg).reduce((a, b) => a > b ? a : b);
    return GlassCard(
      tint: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF122F47), Color(0xFF193743), Color(0xFF282050)],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SizedBox(
        height: 126,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final record in records)
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(record.kg.toStringAsFixed(1), style: t(10, w: FontWeight.w700, color: C.mint)),
              const SizedBox(height: 5),
              Container(
                height: max == min ? 54 : 26 + ((record.kg - min) / (max - min) * 52),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(gradient: C.mintGradient, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 7),
              Text('${record.date.day}', style: t(11, color: C.textDim)),
            ])),
        ]),
      ),
    );
  }

  Widget _recordRow(WeightEntry record) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Icon(Icons.monitor_weight_outlined, size: 19, color: C.mint),
          const SizedBox(width: 10),
          Expanded(child: Text(_date(record.date), style: t(14, w: FontWeight.w600))),
          Text('${record.kg.toStringAsFixed(1)} kg', style: t(16, w: FontWeight.w800)),
        ]),
      );

  _Range _rangeFor(DateTime date) {
    if (_monthly) {
      final start = DateTime(date.year, date.month);
      return _Range(start, DateTime(date.year, date.month + 1));
    }
    final day = DateTime(date.year, date.month, date.day);
    final start = day.subtract(Duration(days: day.weekday - 1));
    return _Range(start, start.add(const Duration(days: 7)));
  }

  _Range _previousRange(_Range range) => _monthly
      ? _Range(DateTime(range.start.year, range.start.month - 1), range.start)
      : _Range(range.start.subtract(const Duration(days: 7)), range.start);

  void _shift(int amount) {
    _anchor = _monthly
        ? DateTime(_anchor.year, _anchor.month + amount, 1)
        : _anchor.add(Duration(days: amount * 7));
  }

  double? _average(List<WeightEntry> values) => values.isEmpty
      ? null
      : values.fold(0.0, (sum, entry) => sum + entry.kg) / values.length;

  String _rangeTitle(_Range range) {
    if (_monthly) return '${_month(range.start.month)} ${range.start.year}';
    return '${range.start.day} ${_month(range.start.month)} – ${range.end.subtract(const Duration(days: 1)).day} ${_month(range.end.subtract(const Duration(days: 1)).month)}';
  }

  String _date(DateTime date) => '${date.day} ${_month(date.month)} ${date.year}';

  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}

class _Range {
  const _Range(this.start, this.end);
  final DateTime start;
  final DateTime end;
}
