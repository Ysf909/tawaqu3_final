import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_model/trade_view_model.dart';

class TradeTabView extends StatelessWidget {
  final VoidCallback onOpenTradeFlow;

  const TradeTabView({
    super.key,
    required this.onOpenTradeFlow,
  });

  @override
  Widget build(BuildContext context) {
    // 👇 get the TradeViewModel from Provider
    final vm = context.watch<TradeViewModel>();

    return Center(
      child: ElevatedButton(
        onPressed: vm.loading
            ? null
            : () async {
                try {
                  // 1) generate trade + save to Supabase history
                  await vm.generate();

                  // 2) (optional) navigate to trade flow or history page
                  onOpenTradeFlow();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trade generated & saved to history'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
        child: vm.loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Generate Trade'),
      ),
    );
  }
}
