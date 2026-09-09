import 'package:flutter/material.dart';
import '../space_theme.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 13});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: SpaceColors.cosmicCyan, shape: BoxShape.circle),
      child: Icon(Icons.check, size: size, color: Colors.black),
    );
  }
}
