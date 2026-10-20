import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../notifications.dart';
import '../state.dart';
import '../widgets/glass.dart';

String fmtTime(int h, int m) {
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String daysText(Set<int> d) {
  if (d.length == 7) return 'Every day';
  if (d.length == 5 && !d.contains(6) && !d.contains(7)) return 'Weekdays';
  if (d.length == 2 && d.contains(6) && d.contains(7)) return 'Weekends';
  final l = d.toList()..sort();
  return l.map((e) => _dayNames[e - 1]).join(', ');
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  static const _presets = <(String, bool, int, int)>[
    ('Log breakfast', true, 8, 30),
    ('Log lunch', true, 13, 30),
    ('Log evening snack', true, 17, 0),
    ('Log dinner', true, 20, 30),
    ('Morning workout log', false, 7, 30),
    ('Evening workout log', false, 19, 0),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = [...s.reminders]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 130),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reminders', style: t(30, w: FontWeight.w800, ls: -0.8)),
                Text('Never forget to log a meal or workout',
                    style: t(14, color: C.textDim)),
              ]),
            ),
            LiquidButton(
              label: 'New',
              icon: Icons.add_alarm_rounded,
              compact: true,
              gradient: C.violetGradient,
              onTap: () => showGlassSheet(context, (_) => const ReminderSheet()),
            ),
          ]),
        ),
        if (!NotificationService.instance.supported)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Text(
                'Notifications work on the Android and iOS apps. On web you can still set up reminders, but they won\'t ring.',
                style: t(13, color: C.textDim)),
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Allow notifications & send a test',
                      style: t(14, w: FontWeight.w600))),
              LiquidButton(
                label: 'Test',
                compact: true,
                onTap: () async {
                  final ok = await NotificationService.instance.requestPermission();
                  if (ok) await NotificationService.instance.showTest();
                  if (context.mounted && !ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Notification permission was denied.')));
                  }
                },
              ),
            ]),
          ),
        const SectionTitle('Quick add'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in _presets)
            Pressable(
              onTap: () {
                final st = context.read<AppState>();
                st.upsertReminder(Reminder(
                  id: st.newReminderId(),
                  diet: p.$2,
                  label: p.$1,
                  hour: p.$3,
                  minute: p.$4,
                ));
                NotificationService.instance.requestPermission();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Text('${p.$2 ? '🍛' : '💪'} ${p.$1} · ${fmtTime(p.$3, p.$4)}',
                    style: t(13, color: C.textDim)),
              ),
            ),
        ]),
        SectionTitle('Your reminders',
            trailing: Text('${list.length}', style: t(14, color: C.textDim))),
        if (list.isEmpty)
          GlassCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                const Text('⏰', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 8),
                Text('No reminders yet', style: t(16, w: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tap a quick-add above to start.',
                    style: t(13, color: C.textDim)),
                if (NotificationService.instance.supported) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await NotificationService.instance.clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('All scheduled DesiFit notifications were cleared.'),
                        ));
                      }
                    },
                    icon: Icon(Icons.notifications_off_outlined, color: C.flame),
                    label: Text('Clear old scheduled notifications',
                        style: t(13, color: C.flame, w: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
          )
        else
          for (final r in list) _tile(context, r),
      ],
    );
  }

  Widget _tile(BuildContext context, Reminder r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('r${r.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<AppState>().removeReminder(r),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          onTap: () =>
              showGlassSheet(context, (_) => ReminderSheet(existing: r)),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: r.diet ? C.heroGradient : C.mintGradient,
              ),
              child: Text(r.diet ? '🍛' : '💪',
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmtTime(r.hour, r.minute),
                    style: t(22, w: FontWeight.w800, ls: -0.5,
                        color: r.enabled ? C.text : C.textFaint)),
                Text('${r.label} · ${daysText(r.days)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t(12.5, color: C.textDim)),
              ]),
            ),
            Switch(
              value: r.enabled,
              activeTrackColor: C.mint,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              onChanged: (v) {
                r.enabled = v;
                context.read<AppState>().upsertReminder(r);
                if (v) NotificationService.instance.requestPermission();
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class ReminderSheet extends StatefulWidget {
  final Reminder? existing;
  const ReminderSheet({super.key, this.existing});

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late bool diet = widget.existing?.diet ?? true;
  late TimeOfDay time = TimeOfDay(
      hour: widget.existing?.hour ?? 20, minute: widget.existing?.minute ?? 0);
  late Set<int> days = {...(widget.existing?.days ?? {1, 2, 3, 4, 5, 6, 7})};
  late final TextEditingController label = TextEditingController(
      text: widget.existing?.label ?? 'Log your dinner');

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.existing == null ? 'New reminder' : 'Edit reminder',
            style: t(22, w: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: [
          GlassChip(
              label: '🍛 Diet log',
              selected: diet,
              onTap: () => setState(() => diet = true)),
          const SizedBox(width: 8),
          GlassChip(
              label: '💪 Workout log',
              selected: !diet,
              activeGradient: C.mintGradient,
              onTap: () => setState(() => diet = false)),
        ]),
        const SizedBox(height: 18),
        Pressable(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (ctx, child) => Theme(
                data: ThemeData.dark(useMaterial3: true).copyWith(
                  colorScheme: ColorScheme.dark(
                      primary: C.saffron, surface: const Color(0xFF1E1445)),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => time = picked);
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                Text(fmtTime(time.hour, time.minute),
                    style: t(46, w: FontWeight.w800, ls: -1.5)),
                Text('Tap to change time', style: t(12.5, color: C.textDim)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Repeat', style: t(15, w: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 1; i <= 7; i++)
              Pressable(
                onTap: () => setState(() {
                  if (days.contains(i)) {
                    if (days.length > 1) days.remove(i);
                  } else {
                    days.add(i);
                  }
                }),
                scale: 0.88,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: days.contains(i) ? C.heroGradient : null,
                    color: days.contains(i)
                        ? null
                        : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                        color: Colors.white
                            .withValues(alpha: days.contains(i) ? 0.5 : 0.15)),
                  ),
                  child: Text(_dayNames[i - 1].substring(0, 1),
                      style: t(14, w: FontWeight.w700)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Message', style: t(15, w: FontWeight.w700)),
        const SizedBox(height: 10),
        GlassField(controller: label, hint: 'e.g. Log your lunch'),
        const SizedBox(height: 24),
        Center(
          child: LiquidButton(
            label: 'Save reminder',
            icon: Icons.check_rounded,
            onTap: () {
              final st = context.read<AppState>();
              st.upsertReminder(Reminder(
                id: widget.existing?.id ?? st.newReminderId(),
                diet: diet,
                label: label.text.trim().isEmpty
                    ? (diet ? 'Log your meal' : 'Log your workout')
                    : label.text.trim(),
                hour: time.hour,
                minute: time.minute,
                enabled: true,
                days: days,
              ));
              NotificationService.instance.requestPermission();
              Navigator.pop(context);
            },
          ),
        ),
      ]),
    );
  }
}
