import 'dart:async';
import 'package:flutter/material.dart';
import '../space_theme.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.ready, required this.child});
  final bool ready;
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _minTime = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _minTime = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ready && _minTime) return widget.child;
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpaceColors.text, width: 1.4),
                  ),
                  child: Icon(Icons.auto_awesome, size: 40, color: SpaceColors.text),
                ),
                const SizedBox(height: 18),
                Text(
                  'Space Social',
                  style: TextStyle(fontFamily: 'GrandHotel', fontSize: 42, color: SpaceColors.text, height: 1),
                ),
                const SizedBox(height: 8),
                Text('Comparte lo que te hace brillar.', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
