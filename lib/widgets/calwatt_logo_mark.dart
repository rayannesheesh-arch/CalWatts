import 'package:flutter/material.dart';

class CalWattLogoMark extends StatelessWidget {
  const CalWattLogoMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      child: Icon(Icons.bolt, color: Colors.white, size: size * 0.65),
    );
  }
}
