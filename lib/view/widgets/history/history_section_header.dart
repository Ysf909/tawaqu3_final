import 'package:flutter/material.dart';

class HistorySectionHeader extends StatelessWidget {
  final String title;
  const HistorySectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
