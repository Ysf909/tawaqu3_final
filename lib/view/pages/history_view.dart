import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/history/history_trade_card.dart';
import 'package:tawaqu3_final/view_model/history_view_model.dart';
import 'package:tawaqu3_final/view/widgets/history/history_section_header.dart';
import 'package:tawaqu3_final/view/widgets/history/history_skeleton.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryViewModel>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _sortLabel(HistorySort s) {
    switch (s) {
      case HistorySort.newest:
        return 'Newest';
      case HistorySort.oldest:
        return 'Oldest';
      case HistorySort.entryHigh:
        return 'Entry (High)';
      case HistorySort.entryLow:
        return 'Entry (Low)';
    }
  }

  Future<void> _refresh() => context.read<HistoryViewModel>().loadHistory();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade History'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: vm.loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: vm.loading
          ? const HistorySkeleton()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.35),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withOpacity(0.12),
                                  cs.secondary.withOpacity(0.08),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timeline_rounded, color: cs.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ' trades',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: vm.toggleGroupByDay,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: cs.outlineVariant.withOpacity(
                                          0.35,
                                        ),
                                      ),
                                      color: cs.surface.withOpacity(0.55),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          vm.groupByDay
                                              ? Icons.view_day_rounded
                                              : Icons.view_agenda_rounded,
                                          size: 18,
                                          color: cs.onSurface.withOpacity(0.75),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          vm.groupByDay ? 'Grouped' : 'Flat',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: cs.onSurface.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.outlineVariant.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchCtl,
                                    onChanged: vm.setQuery,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText:
                                          'Search entry, SL, TP, lot, name, date...',
                                      prefixIcon: Icon(Icons.search_rounded),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              PopupMenuButton<HistorySort>(
                                tooltip: 'Sort',
                                onSelected: vm.setSort,
                                itemBuilder: (_) => HistorySort.values
                                    .map(
                                      (s) => PopupMenuItem(
                                        value: s,
                                        child: Text(_sortLabel(s)),
                                      ),
                                    )
                                    .toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.outlineVariant.withOpacity(
                                        0.35,
                                      ),
                                    ),
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.25),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.sort_rounded),
                                      const SizedBox(width: 8),
                                      Text(
                                        _sortLabel(vm.sort),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.expand_more_rounded),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (vm.error != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                vm.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (vm.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 56,
                                color: cs.onSurface.withOpacity(0.35),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No trades yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your saved trades will appear here in a clean timeline.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      sliver: SliverList.builder(
                        itemCount: vm.items.length,
                        itemBuilder: (context, i) {
                          final item = vm.items[i];
                          if (item is HistoryDayHeader) {
                            return HistorySectionHeader(title: item.day);
                          }
                          final t = (item as HistoryTradeItem).trade;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: HistoryTradeCard(trade: t),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
