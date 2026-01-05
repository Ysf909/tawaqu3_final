import 'package:flutter/material.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget box({double h = 18, double w = double.infinity, double r = 14}) {
      return Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cs.surfaceContainerHighest.withOpacity(0.18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: cs.primary.withOpacity(0.12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: box(h: 18, r: 10)),
                  const SizedBox(width: 10),
                  box(h: 26, w: 90, r: 999),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: box(h: 44, r: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: box(h: 44, r: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: box(h: 44, r: 16)),
                ],
              ),
              const SizedBox(height: 12),
              box(h: 14, w: 120, r: 10),
            ],
          ),
        );
      },
    );
  }
}
