import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(subtitle, style: TextStyle(color: AppTheme.tertiary(context), fontSize: 11)),
      ],
    );
  }
}
