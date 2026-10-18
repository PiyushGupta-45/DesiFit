import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';
import '../state.dart';
import '../widgets/glass.dart';

class GoalsScreen extends StatefulWidget {
  final bool onboarding;
  final VoidCallback? onDone;
  const GoalsScreen({super.key, this.onboarding = false, this.onDone});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _passwordEditor = false;
  bool _goalsOpen = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  static const _activities = <(String, double)>[
    ('Desk job', 1.2),
    ('Light', 1.375),
    ('Moderate', 1.55),
    ('Very active', 1.725),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final p = s.profile;
    void edit(void Function() f) => context.read<AppState>().updateProfile((_) => f());

    return ListView(
      padding: EdgeInsets.fromLTRB(18, widget.onboarding ? 60 : 16, 18, 130),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.onboarding ? 'Namaste 🙏' : 'Profile',
                style: t(32, w: FontWeight.w800, ls: -0.8)),
            const SizedBox(height: 4),
            Text(
                widget.onboarding
                    ? 'Tell us a little about you to set smart daily targets.'
                    : 'Account settings and body details',
                style: t(14, color: C.textDim)),
          ]),
        ),
        if (!widget.onboarding)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ThemeSwitch(
                light: s.lightMode,
                onChanged: s.setLightMode,
              ),
            ),
          ),
        if (!widget.onboarding) ...[
          const SectionTitle('Account'),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: C.violetGradient),
                  child: const Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auth.name?.isNotEmpty == true ? auth.name! : 'DesiFit member', style: t(16, w: FontWeight.w800)),
                  Text(auth.email ?? '', style: t(12.5, color: C.textDim)),
                ])),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Icon(auth.hasPassword ? Icons.lock_rounded : Icons.g_mobiledata_rounded, size: 18, color: auth.hasPassword ? C.mint : C.sky),
                const SizedBox(width: 8),
                Expanded(child: Text(auth.hasPassword ? 'Email & password sign-in enabled' : 'Signed in with Google', style: t(13, color: C.textDim))),
                TextButton(
                  onPressed: () => setState(() => _passwordEditor = !_passwordEditor),
                  child: Text(auth.hasPassword ? 'Change password' : 'Set password'),
                ),
              ]),
              if (_passwordEditor) ...[
                const SizedBox(height: 8),
                if (auth.hasPassword) ...[
                  GlassField(controller: _currentPassword, hint: 'Current password', icon: Icons.lock_outline_rounded, obscureText: true),
                  const SizedBox(height: 10),
                ],
                GlassField(controller: _newPassword, hint: 'New password (min. 8 characters)', icon: Icons.lock_reset_rounded, obscureText: true),
                if (auth.error != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.error!, style: t(12, color: C.flame)),
                ],
                const SizedBox(height: 10),
                LiquidButton(
                  label: auth.busy ? 'Saving...' : 'Save password',
                  compact: true,
                  icon: Icons.check_rounded,
                  onTap: auth.busy ? null : () async {
                    await auth.savePassword(currentPassword: _currentPassword.text, newPassword: _newPassword.text);
                    if (mounted && auth.error == null) {
                      _currentPassword.clear();
                      _newPassword.clear();
                      setState(() => _passwordEditor = false);
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: TextButton.styleFrom(foregroundColor: C.flame),
                ),
              ),
            ]),
          ),
          const SectionTitle('Fitness plan'),
          Pressable(
            onTap: () => setState(() => _goalsOpen = !_goalsOpen),
            child: GlassCard(
              tint: C.violetGradient,
              child: Row(children: [
                const Icon(Icons.flag_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Goals & daily targets', style: t(16, w: FontWeight.w800, color: Colors.white)),
                  Text(_goalsOpen ? 'Tap to hide goal settings' : 'Calories, protein and fitness goal',
                      style: t(12, color: Colors.white70)),
                ])),
                Icon(_goalsOpen ? Icons.expand_less_rounded : Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 20),
              ]),
            ),
          ),
        ],
        const SectionTitle('Body profile'),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GlassChip(
                  label: '♂ Male',
                  selected: p.male,
                  onTap: () => edit(() => p.male = true)),
              const SizedBox(width: 8),
              GlassChip(
                  label: '♀ Female',
                  selected: !p.male,
                  onTap: () => edit(() => p.male = false)),
            ]),
            const SizedBox(height: 8),
            _slider('Age', p.age.toDouble(), 14, 80, 'yrs',
                (v) => edit(() => p.age = v.round()), step: 1),
            _slider('Height', p.heightCm, 130, 210, 'cm',
                (v) => edit(() => p.heightCm = v.roundToDouble()), step: 1),
            _slider('Weight', p.weightKg, 30, 160, 'kg',
                (v) => edit(() => p.weightKg = (v * 10).round() / 10),
                decimals: 1,
                step: 0.1),
            const SizedBox(height: 8),
            Text('Activity level', style: t(14, w: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final a in _activities)
                GlassChip(
                  label: a.$1,
                  selected: p.activity == a.$2,
                  activeGradient: C.mintGradient,
                  onTap: () => edit(() => p.activity = a.$2),
                ),
            ]),
            if (widget.onboarding || _goalsOpen) ...[
              const SizedBox(height: 16),
              Text('Goal', style: t(14, w: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GlassChip(label: '📉 Lose fat', selected: p.goal < 0,
                    onTap: () => edit(() => p.goal = -1)),
                GlassChip(label: '⚖️ Maintain', selected: p.goal == 0,
                    onTap: () => edit(() => p.goal = 0)),
                GlassChip(label: '💪 Build muscle', selected: p.goal > 0,
                    onTap: () => edit(() => p.goal = 1)),
              ]),
            ],
          ]),
        ),
        if (widget.onboarding || _goalsOpen) ...[
          const SectionTitle('Daily targets'),
          GlassCard(
          child: Column(children: [
            _slider('Calories', p.calorieTarget.toDouble(), 1000, 4000, 'kcal',
                (v) => edit(() => p.calorieTarget = (v / 10).round() * 10),
                gradient: C.heroGradient,
                step: 10),
            _slider('Protein', p.proteinTarget.toDouble(), 30, 250, 'g',
                (v) => edit(() => p.proteinTarget = v.round()),
                gradient: C.mintGradient,
                step: 1),
            _slider('Calories to burn', p.burnTarget.toDouble(), 0, 1200, 'kcal',
                (v) => edit(() => p.burnTarget = (v / 10).round() * 10),
                gradient: C.violetGradient,
                step: 10),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Suggested for you',
                        style: t(13, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        '${p.suggestedCalories} kcal · ${p.suggestedProtein} g protein\n'
                        'BMR ${p.bmr.round()} · TDEE ${p.tdee.round()}',
                        style: t(12.5, color: C.textDim, h: 1.4)),
                  ]),
                ),
                LiquidButton(
                  label: 'Apply',
                  compact: true,
                  onTap: () => edit(() {
                    p.calorieTarget = p.suggestedCalories;
                    p.proteinTarget = p.suggestedProtein;
                  }),
                ),
              ]),
            ),
          ]),
          ),
        ],
        if (widget.onboarding) ...[
          const SizedBox(height: 26),
          Center(
            child: LiquidButton(
              label: 'Start tracking',
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                widget.onDone?.call();
                context.read<AppState>().finishOnboarding();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _slider(String label, double v, double min, double max, String unit,
      ValueChanged<double> onChanged,
      {Gradient? gradient, int decimals = 0, double step = 1}) {
    final sliderGradient = gradient ?? C.heroGradient;
    final value = v.clamp(min, max).toDouble();
    void changeBy(double delta) => onChanged((value + delta).clamp(min, max).toDouble());
    void submit(String text) {
      final typed = double.tryParse(text.replaceAll(',', '.'));
      if (typed != null) onChanged(typed.clamp(min, max).toDouble());
    }

    return Column(children: [
      Row(children: [
        Text(label, style: t(14, w: FontWeight.w700)),
        const Spacer(),
        SizedBox(
          width: 76,
          child: TextFormField(
            key: ValueKey('$label-$value'),
            initialValue: value.toStringAsFixed(decimals),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
            style: t(15, w: FontWeight.w800, color: sliderGradient.colors.first),
            onFieldSubmitted: submit,
            decoration: InputDecoration(
              isDense: true,
              suffixText: unit,
              suffixStyle: t(11, color: C.textDim),
              contentPadding: const EdgeInsets.symmetric(vertical: 7),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24))),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sliderGradient.colors.first)),
            ),
          ),
        ),
      ]),
      Row(children: [
        _adjustButton(Icons.remove_rounded, () => changeBy(-step)),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: sliderGradient.colors.first,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
              thumbColor: Colors.white,
              overlayColor: sliderGradient.colors.first.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _adjustButton(Icons.add_rounded, () => changeBy(step)),
      ]),
    ]);
  }

  Widget _adjustButton(IconData icon, VoidCallback onTap) => SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          color: C.text,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            shape: const CircleBorder(),
          ),
        ),
      );
}

class _ThemeSwitch extends StatelessWidget {
  final bool light;
  final ValueChanged<bool> onChanged;

  const _ThemeSwitch({required this.light, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: light ? 'Switch to dark theme' : 'Switch to light theme',
      child: GestureDetector(
        onTap: () => onChanged(!light),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 94,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: light ? 0.72 : 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (light ? C.violet : Colors.white).withValues(alpha: 0.28),
            ),
          ),
          child: Stack(children: [
            Align(
              alignment: light ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: light ? C.heroGradient : C.mintGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (light ? C.saffron : C.mint).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  light ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(Icons.dark_mode_outlined,
                  size: 15, color: light ? C.textFaint : Colors.transparent),
              Icon(Icons.light_mode_outlined,
                  size: 15, color: light ? Colors.transparent : C.textFaint),
            ]),
          ]),
        ),
      ),
    );
  }
}
