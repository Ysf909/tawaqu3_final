import 'package:flutter/material.dart';

class TradeTabView extends StatelessWidget {
  final VoidCallback onOpenTradeFlow;

  const TradeTabView({
    super.key,
    required this.onOpenTradeFlow,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onOpenTradeFlow,
        child: const Text(' Generate Trade'),
      ),
    );
  }
}
