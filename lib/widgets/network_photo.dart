import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.person, color: LumaColors.textTertiary),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _err(),
      );
    }
    final file = File(url);
    if (!file.existsSync()) return _err();
    return Image.file(file, fit: fit, gaplessPlayback: true, errorBuilder: (_, __, ___) => _err());
  }

  Widget _err() => Container(
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: LumaColors.textTertiary),
      );
}

class Avatar extends StatelessWidget {
  const Avatar(this.url, {super.key, this.size = 32, this.onTap});
  final String url;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final img = ClipOval(
      child: SizedBox(width: size, height: size, child: NetworkPhoto(url)),
    );
    if (onTap == null) return img;
    return GestureDetector(onTap: onTap, child: img);
  }
}
