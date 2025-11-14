import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import '../../core/router/app_router.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: CircleAvatar(child: Text('JD')),
            title: Text('John Doe'),
            subtitle: Text('john.doe@email.com'),
          ),
          const Divider(),
          // Connects
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Connects'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.connectsRoute,
              );
            },
          ),
          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.notificationsRoute,
              );
            },
          ),
          // History
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.historyRoute,
              );
            },
          ),
          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.SettingsRoute,
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRouter.authRoute,
              );
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Menu'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 1000;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: menu),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [menu],
            );
          },
        ),
      ),
    );
  }
}
