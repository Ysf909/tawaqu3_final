import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/notifications_view_model.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final noti = context.watch<NotificationsViewModel>();

    final content = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('', Title: ''),
          SwitchListTile(
            title: const Text('Trade Alerts'),
            value: noti.tradeAlerts,
            onChanged: (v) {
              noti.tradeAlerts = v;
              noti.notifyListeners();
            },
          ),
          SwitchListTile(
            title: const Text('Price Alerts'),
            value: noti.priceAlerts,
            onChanged: (v) {
              noti.priceAlerts = v;
              noti.notifyListeners();
            },
          ),
          SwitchListTile(
            title: const Text('News Updates'),
            value: noti.newsUpdates,
            onChanged: (v) {
              noti.newsUpdates = v;
              noti.notifyListeners();
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: noti.emailNotifications,
            onChanged: (v) {
              noti.emailNotifications = v;
              noti.notifyListeners();
            },
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: noti.pushNotifications,
            onChanged: (v) {
              noti.pushNotifications = v;
              noti.notifyListeners();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: noti.disableAll,
                child: const Text('DISABLE ALL'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: noti.save,
                child: const Text('SAVE CHANGES'),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Notifications'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [content]),
    );
  }
}
