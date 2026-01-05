import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/history_trade.dart';

class HistoryTradeCard extends StatelessWidget {
  final HistoryTrade trade;
  const HistoryTradeCard({super.key, required this.trade});

  String _timeLabel(DateTime d) {
    final t = d.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _outcomeText() {
    final o = trade.outcome?.toString() ?? '';
    if (o.isEmpty) return '—';
    return o.split('.').last; // works with enums
  }

  Color _outcomeColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = _outcomeText().toLowerCase();
    if (s.contains('win') || s.contains('profit') || s.contains('tp'))
      return Colors.green;
    if (s.contains('loss') || s.contains('sl')) return Colors.red;
    return cs.onSurface.withOpacity(0.55);
  }

  void _openDetails(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final when = trade.dateSaved.toLocal().toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        Widget row(String label, String value) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: cs.surfaceContainerHighest.withOpacity(0.25),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trade Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                row(
                  'Trader',
                  '${trade.fname} ${trade.lname}'.trim().isEmpty
                      ? '—'
                      : '${trade.fname} ${trade.lname}',
                ),
                row('Outcome', _outcomeText()),
                row('Entry', '${trade.previousEntry ?? '-'}'),
                row('SL', '${trade.previousSl ?? '-'}'),
                row('TP', '${trade.previousTp ?? '-'}'),
                row('Lot', '${trade.previousLot ?? '-'}'),
                row('Saved at', when),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final trader = '${trade.fname} ${trade.lname}'.trim();
    final outcomeColor = _outcomeColor(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openDetails(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.30)),
          color: cs.surfaceContainerHighest.withOpacity(0.20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: cs.primary.withOpacity(0.14),
                  ),
                  child: Icon(Icons.show_chart_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trader.isEmpty ? 'Trade' : trader,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurface.withOpacity(0.75),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Entry: ${trade.previousEntry ?? '-'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timeLabel(trade.dateSaved),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _outcomeText(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: outcomeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _Badge(
                    label: 'SL',
                    value: '${trade.previousSl ?? '-'}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Badge(
                    label: 'TP',
                    value: '${trade.previousTp ?? '-'}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Badge(
                    label: 'Lot',
                    value: '${trade.previousLot ?? '-'}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Tap for details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;

  const _Badge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface.withOpacity(0.65),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.60),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
