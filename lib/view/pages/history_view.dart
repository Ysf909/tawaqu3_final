import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view_model/history_view_model.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HistoryViewModel>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();

    if (vm.loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Trade History')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trade History')),
      body: vm.trades.isEmpty
          ? const Center(child: Text('No trades in history yet.'))
          : ListView.builder(
              itemCount: vm.trades.length,
              itemBuilder: (context, i) {
                final t = vm.trades[i];
                return ListTile(
                  title: Text('Entry: ${t.previousEntry}'),
                  subtitle: Text(
                    'SL: ${t.previousSl}  TP: ${t.previousTp}  Lot: ${t.previousLot}\n'
                    ' ${t.dateSaved}',
                  ),
                );
              },
            ),
    );
  }
}
