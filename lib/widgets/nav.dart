
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import 'glass.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

/// Floating glass tab bar with a liquid "lens" that glides between tabs.
class LiquidNavBar extends StatelessWidget {
  final int index;
  final List<NavItem> items;
  final ValueChanged<int> onChanged;
  const LiquidNavBar({
    super.key,
    required this.index,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    C.isLight
                        ? Colors.white.withValues(alpha: 0.88)
                        : const Color(0xFF09263A).withValues(alpha: 0.90),
                    C.isLight
                        ? C.bg2.withValues(alpha: 0.76)
                        : const Color(0xFF061A2B).withValues(alpha: 0.82),
                  ],
                ),
                border: Border.all(
                    color: (C.isLight ? C.sky : C.mint)
                        .withValues(alpha: C.isLight ? 0.22 : 0.30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: C.isLight ? 0.10 : 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth / items.length;
                return Stack(children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    left: index * w + 4,
                    top: 6,
                    width: w - 8,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: C.heroGradient,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                              color: (C.isLight ? C.violet : C.magenta)
                                  .withValues(alpha: 0.32),
                              blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onChanged(i);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == index ? 1.15 : 1,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  child: Icon(items[i].icon,
                                  size: 22,
                                      color: i == index ? Colors.white : C.textDim),
                                ),
                                const SizedBox(height: 2),
                                Text(items[i].label,
                                    style: t(9.5,
                                        w: i == index
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color:
                                            i == index ? Colors.white : C.textDim)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ]);
              }),
            ),
          ),
      ),
    );
  }
}

/// Horizontal strip of the last 14 days. Reads/writes AppState.selectedDate.
class DateStrip extends StatefulWidget {
  const DateStrip({super.key});

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = DateTime.now();
    final days = List.generate(
        14, (i) => DateTime(today.year, today.month, today.day - (13 - i)));
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 74,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = days[i];
          final sel = sameDay(d, s.selectedDate);
          final hasData = s.dietOn(d).isNotEmpty || s.workoutsOn(d).isNotEmpty;
          return Pressable(
            onTap: () => context.read<AppState>().selectDate(d),
            scale: 0.92,
            child: Container(
              width: 54,
              decoration: BoxDecoration(
                gradient: sel ? C.heroGradient : null,
                color: sel ? null : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withValues(alpha: sel ? 0.55 : 0.14)),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: C.flame.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6))
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(wd[d.weekday - 1],
                      style: t(11.5, color: sel ? Colors.white : C.textDim)),
                  const SizedBox(height: 3),
                  Text('${d.day}', style: t(19, w: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasData
                          ? (sel ? Colors.white : C.mint)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
