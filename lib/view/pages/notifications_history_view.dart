import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/notifications_view_model.dart';
import '../../view_model/history_view_model.dart';

class NotificationsHistoryView extends StatelessWidget {
  const NotificationsHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final noti = context.watch<NotificationsViewModel>();
    final history = context.watch<HistoryViewModel>();

    final notifications = CardContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Notifications'),
        SwitchListTile(title: const Text('Trade Alerts'), value: noti.tradeAlerts, onChanged: (v){ noti.tradeAlerts=v; noti.notifyListeners(); }),
        SwitchListTile(title: const Text('Price Alerts'), value: noti.priceAlerts, onChanged: (v){ noti.priceAlerts=v; noti.notifyListeners(); }),
        SwitchListTile(title: const Text('News Updates'), value: noti.newsUpdates, onChanged: (v){ noti.newsUpdates=v; noti.notifyListeners(); }),
        SwitchListTile(title: const Text('Email Notifications'), value: noti.emailNotifications, onChanged: (v){ noti.emailNotifications=v; noti.notifyListeners(); }),
        SwitchListTile(title: const Text('Push Notifications'), value: noti.pushNotifications, onChanged: (v){ noti.pushNotifications=v; noti.notifyListeners(); }),
        const SizedBox(height: 8),
        Row(children: [
          OutlinedButton(onPressed: noti.disableAll, child: const Text('DISABLE ALL')),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: noti.save, child: const Text('SAVE CHANGES')),
        ]),
      ],
    ));

    final tradeHistory = CardContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('History'),
        Wrap(spacing: 16, runSpacing: 8, children: [
          Chip(label: Text('Total Profit: +\$${history.totalProfit.toStringAsFixed(2)}')),
          Chip(label: Text('Win Rate: ${history.winRate.toStringAsFixed(1)}%')),
        ]),
        const SizedBox(height: 12),
        ...history.trades.map((t) => ListTile(
              title: Text('${t.pair} · ${t.direction}'),
              subtitle: Text('Entry ${t.entry} • Exit ${t.takeProfit} • Lot ${t.lot}'),
              trailing: Text(
                (t.profit ?? 0) >= 0 ? '+\$${t.profit!.toStringAsFixed(0)}' : '-\$${(t.profit! * -1).toStringAsFixed(0)}',
                style: TextStyle(color: (t.profit ?? 0) >= 0 ? Colors.greenAccent : Colors.redAccent),
              ),
            )),
      ],
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & History')),
      body: LayoutBuilder(builder: (context, c){
        final wide = c.maxWidth > 1000;
        if (wide) return Row(children: [Expanded(child: notifications), Expanded(child: tradeHistory)]);
        return ListView(children: [notifications, tradeHistory]);
      }),
    );
  }
}

