import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central adaptive palette. Keeping colours here makes every screen switch
/// together instead of maintaining a separate light-theme copy per widget.
class C {
  static bool _light = false;
  static bool get isLight => _light;
  static void setLight(bool value) => _light = value;

  // Dark: midnight-ocean glass. Light: warm paper with sunny colour.
  // This intentionally uses different palettes, not a washed-out dark theme.
  static Color get bg1 =>
      _light ? const Color(0xFFFFF8F0) : const Color(0xFF070A18);
  static Color get bg2 =>
      _light ? const Color(0xFFFCE3CD) : const Color(0xFF111B38);
  static Color get surface =>
      _light ? const Color(0xFFFFFCF8) : const Color(0xFF17244A);
  static Color get saffron => _light ? const Color(0xFFF59E0B) : const Color(0xFFFFCB5B);
  static Color get flame => _light ? const Color(0xFFEA5B54) : const Color(0xFFFF718D);
  static Color get magenta => _light ? const Color(0xFFD84A8B) : const Color(0xFFFF78B9);
  static Color get violet => _light ? const Color(0xFF5967D8) : const Color(0xFF8994FF);
  static Color get mint => _light ? const Color(0xFF078B82) : const Color(0xFF42D9C4);
  static Color get sky => _light ? const Color(0xFF238BDB) : const Color(0xFF45C7FF);
  static Color get text =>
      _light ? const Color(0xFF26324A) : const Color(0xFFF4F7FF);
  static Color get textDim =>
      _light ? const Color(0xB326324A) : const Color(0xB3DDE7FF);
  static Color get textFaint =>
      _light ? const Color(0x8026324A) : const Color(0x80DDE7FF);

  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _light
            ? [const Color(0xFFEF7659), const Color(0xFFF6B73C)]
            : [const Color(0xFF6277FF), const Color(0xFF38C8FF)],
      );
  static LinearGradient get mintGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _light
            ? [const Color(0xFF04A999), const Color(0xFF3E9EF0)]
            : [const Color(0xFF28CDB4), const Color(0xFF45C7FF)],
      );
  static LinearGradient get violetGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _light
            ? [const Color(0xFF6272DA), const Color(0xFFD95C9B)]
            : [const Color(0xFF7E87FF), const Color(0xFFFF74B0)],
      );
}

TextStyle t(double size,
        {FontWeight w = FontWeight.w500,
        Color? color,
        double? h,
        double? ls}) =>
    TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color ?? C.text,
        height: h,
        letterSpacing: ls);

/// Slow drifting aurora blobs behind everything – gives the glass something
/// colourful to refract.
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  // Kept static: an animating backdrop forces every glass surface to redraw.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, Color color, Offset p) => Positioned(
        left: p.dx - size / 2,
        top: p.dy - size / 2,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: C.isLight ? 0.30 : 0.48),
              color.withValues(alpha: 0.0),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.bg2, C.bg1],
        ),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return Stack(fit: StackFit.expand, children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final a = _c.value * 2 * math.pi;
              return Stack(children: [
                _blob(w * 1.0, C.violet,
                    Offset(w * (0.15 + 0.10 * math.sin(a)), h * (0.12 + 0.05 * math.cos(a)))),
                _blob(w * 0.95, C.magenta,
                    Offset(w * (0.95 + 0.08 * math.cos(a * 1.3)), h * (0.34 + 0.06 * math.sin(a)))),
                _blob(w * 0.9, C.saffron,
                    Offset(w * (0.05 + 0.10 * math.cos(a)), h * (0.66 + 0.05 * math.sin(a * 1.2)))),
                _blob(w * 0.85, C.mint,
                    Offset(w * (0.85 + 0.06 * math.sin(a * 0.8)), h * (0.92 + 0.03 * math.cos(a)))),
              ]);
            },
          ),
          widget.child,
        ]);
      }),
    );
  }
}

/// Paints the glossy "liquid glass" rim: bright top-left edge, soft
/// bottom-right edge, plus a thin specular highlight along the top.
class _RimPainter extends CustomPainter {
  final double radius;
  final double strength;
  _RimPainter(this.radius, this.strength);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius));
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.75 * strength),
          Colors.white.withValues(alpha: 0.08 * strength),
          Colors.white.withValues(alpha: 0.02 * strength),
          Colors.white.withValues(alpha: 0.40 * strength),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rr, rim);

    // specular sheen on the upper edge
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.22 * strength),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, math.min(size.height, 46)));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, math.min(size.height, 46)), sheen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RimPainter o) => o.radius != radius || o.strength != strength;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Gradient? tint;
  final double strength;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.blur = 26,
    this.tint,
    this.strength = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Keep the glass colour/highlight but avoid a ClipRRect + CustomPaint layer
    // for every item in long scrolling lists.
    final card = RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: tint ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (C.isLight ? Colors.white : C.surface)
                      .withValues(alpha: (C.isLight ? 0.88 : 0.88) * strength),
                  (C.isLight ? C.bg2 : C.bg2)
                      .withValues(alpha: (C.isLight ? 0.48 : 0.64) * strength),
                ],
              ),
          border: Border.all(
              color: (C.isLight ? C.saffron : C.sky).withValues(
                  alpha: (C.isLight ? 0.24 : 0.28) * strength)),
          boxShadow: C.isLight
              ? [
                  BoxShadow(
                    color: const Color(0xFF28506F).withValues(alpha: 0.09),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap!, child: card);
  }
}

/// Squishy press feedback – scales down with a spring when touched.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const Pressable({super.key, required this.child, required this.onTap, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Glossy gradient "liquid" button.
class LiquidButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool compact;

  const LiquidButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final buttonGradient = gradient ?? C.heroGradient;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        onTap: onTap ?? () {},
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24, vertical: compact ? 10 : 15),
          decoration: BoxDecoration(
            gradient: buttonGradient,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: (buttonGradient.colors.first).withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // gloss
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: 0.38),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(label, style: t(compact ? 14 : 16, w: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small glass pill used for chips / selectors.
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Gradient? activeGradient;
  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? (activeGradient ?? C.heroGradient) : null,
          color: selected
              ? null
              : (C.isLight ? Colors.white : Colors.white)
                  .withValues(alpha: C.isLight ? 0.58 : 0.09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: (C.isLight ? C.violet : Colors.white).withValues(
                  alpha: selected ? 0.5 : (C.isLight ? 0.18 : 0.16))),
        ),
        child: Text(label,
            style: t(13.5,
                w: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : C.textDim)),
      ),
    );
  }
}

class GlassField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final String? suffix;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  const GlassField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.onChanged,
    this.keyboardType,
    this.suffix,
    this.obscureText = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (C.isLight ? Colors.white : Colors.white)
            .withValues(alpha: C.isLight ? 0.64 : 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: (C.isLight ? C.violet : Colors.white)
                .withValues(alpha: C.isLight ? 0.18 : 0.16)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: t(16),
        cursorColor: C.saffron,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t(15, color: C.textFaint),
          prefixIcon:
              icon == null ? null : Icon(icon, color: C.textDim, size: 20),
          suffixText: suffix,
          suffixStyle: t(14, color: C.textDim),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
    );
  }
}

/// Glass bottom sheet helper.
Future<T?> showGlassSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final inset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: CustomPaint(
              foregroundPainter: _RimPainter(36, 1),
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.92),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      C.surface.withValues(alpha: C.isLight ? 0.98 : 0.96),
                      C.bg2.withValues(alpha: C.isLight ? 0.98 : 0.96),
                    ],
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Flexible(child: builder(ctx)),
                ]),
              ),
          ),
        ),
      );
    },
  );
}

/// Animated circular progress ring with gradient stroke.
class GlowRing extends StatelessWidget {
  final double progress; // 0..1+
  final double size;
  final double stroke;
  final Gradient? gradient;
  final Widget? child;
  const GlowRing({
    super.key,
    required this.progress,
    required this.size,
    this.stroke = 16,
    this.gradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ringGradient = gradient ?? C.heroGradient;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, ringGradient),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, stroke;
  final Gradient gradient;
  _RingPainter(this.v, this.stroke, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (v <= 0) return;

    final colors = (gradient as LinearGradient).colors;
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [...colors, colors.first],
      transform: const GradientRotation(-math.pi / 2),
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = sweep.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = sweep.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, glow);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v;
}

/// Thin glass progress bar with a label row.
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target; // 0 = no target
  final String unit;
  final Gradient gradient;
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.gradient,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final frac = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: t(13, color: C.textDim)),
        const Spacer(),
        Text(
          target > 0
              ? '${value.round()} / ${target.round()}$unit'
              : '${value.round()}$unit',
          style: t(13, w: FontWeight.w700),
        ),
      ]),
      const SizedBox(height: 7),
      LayoutBuilder(builder: (context, box) {
        return Stack(children: [
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: frac),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Container(
              height: 9,
              width: box.maxWidth * v,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.5),
                      blurRadius: 8)
                ],
              ),
            ),
          ),
        ]);
      }),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 22, 6, 10),
        child: Row(children: [
          Text(text, style: t(18, w: FontWeight.w800, ls: -0.2)),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
      );
}
