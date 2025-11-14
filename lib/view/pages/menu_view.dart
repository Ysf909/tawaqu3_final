import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../core/router/app_router.dart';
import '../../view_model/settings_view_model.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    final menu = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Menu'),
          const ListTile(
            leading: CircleAvatar(child: Text('JD')),
            title: Text('John Doe'),
            subtitle: Text('john.doe@email.com'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.link),
            title: Text('Connects'),
          ),
          
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
              
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    ListTile(
            leading: const Icon(Icons.add),
            title: const Text('connects'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.connectsRoute,
              );
            },
          ); 

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: LayoutBuilder(
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
            children: [menu],
          );
        },
      ),
    );
  }
}
