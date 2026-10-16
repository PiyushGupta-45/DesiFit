import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette: deep night-indigo with saffron, magenta and mint accents.
class C {
  static const bg1 = Color(0xFF0B0820);
  static const bg2 = Color(0xFF1A0F3C);
  static const saffron = Color(0xFFFFA94D);
  static const flame = Color(0xFFFF6B4A);
  static const magenta = Color(0xFFE5488F);
  static const violet = Color(0xFF7B5CFF);
  static const mint = Color(0xFF3DDBB0);
  static const sky = Color(0xFF4DB8FF);
  static const text = Color(0xFFF6F3FF);
  static const textDim = Color(0xB3F6F3FF);
  static const textFaint = Color(0x80F6F3FF);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffron, flame, magenta],
  );
  static const mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, sky],
  );
  static const violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, magenta],
  );
}

TextStyle t(double size,
        {FontWeight w = FontWeight.w500,
        Color color = C.text,
        double? h,
        double? ls}) =>
    TextStyle(
        fontSize: size, fontWeight: w, color: color, height: h, letterSpacing: ls);

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
              color.withValues(alpha: 0.75),
              color.withValues(alpha: 0.0),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
                  Colors.white.withValues(alpha: 0.17 * strength),
                  Colors.white.withValues(alpha: 0.05 * strength),
                ],
              ),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.20 * strength)),
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
  final Gradient gradient;
  final bool compact;

  const LiquidButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = C.heroGradient,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        onTap: onTap ?? () {},
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24, vertical: compact ? 10 : 15),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: (gradient.colors.first).withValues(alpha: 0.45),
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
          color: selected ? null : Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.5 : 0.16)),
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

  const GlassField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.onChanged,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
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
                      const Color(0xFF2A1B5C).withValues(alpha: 0.78),
                      const Color(0xFF120C2E).withValues(alpha: 0.92),
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
  final Gradient gradient;
  final Widget? child;
  const GlowRing({
    super.key,
    required this.progress,
    required this.size,
    this.stroke = 16,
    this.gradient = C.heroGradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, gradient),
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
