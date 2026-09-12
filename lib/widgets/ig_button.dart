import 'package:flutter/material.dart';
import '../space_theme.dart';

/// Botones Instagram 2026: Seguir azul, secundarios gris #EFEFEF.
class IgButton extends StatelessWidget {
  const IgButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.height = 32,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary ? const Color(0xFF0095F6) : SpaceColors.btn,
          foregroundColor: primary ? Colors.white : SpaceColors.onBtn,
          disabledBackgroundColor: const Color(0xFFB2DFFC),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: Size(expanded ? double.infinity : 0, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class IgFollowButton extends StatelessWidget {
  const IgFollowButton({super.key, required this.following, required this.onTap, this.pending = false});
  final bool following;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = following ? 'Siguiendo' : pending ? 'Solicitado' : 'Seguir';
    return IgButton(label: label, onTap: onTap, primary: !following && !pending);
  }
}

class IgHandle extends StatelessWidget {
  const IgHandle({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: SpaceColors.hairline, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class IgTextFieldDecoration {
  static InputDecoration of(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: SpaceColors.textMuted),
      filled: true,
      fillColor: SpaceColors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDBDBDB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFA8A8A8)),
      ),
    );
  }
}
