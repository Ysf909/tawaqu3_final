import 'package:flutter/material.dart';

class UserProfitCard extends StatelessWidget {
  final bool isLoading;
  final double? profit;
  final String? error;
  final DateTime? updatedAt;
  final VoidCallback onRefresh;

  const UserProfitCard({
    super.key,
    required this.isLoading,
    required this.profit,
    required this.error,
    required this.updatedAt,
    required this.onRefresh,
  });

  String _format(double v) {
    final sign = v < 0 ? '-' : '';
    return '$sign${v.abs().toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final value = profit ?? 0.0;
    final isPositive = value >= 0;

    final valueColor = isPositive ? Colors.green : Colors.red;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.14),
              cs.secondary.withOpacity(0.10),
            ],
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Profit',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurface.withOpacity(0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isLoading
                        ? Row(
                            key: const ValueKey('loading'),
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    cs.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Loading...',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(0.8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key: ValueKey('profit_${value.toStringAsFixed(2)}'),
                            '${_format(value)} USD',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: valueColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      error!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (updatedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Updated: ${updatedAt!.toLocal()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                color: cs.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
