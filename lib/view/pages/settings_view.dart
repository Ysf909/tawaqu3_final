import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import '../../view_model/settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final menu = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use your real fields: isDark + toggleTheme()
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: vm.isDark,
            onChanged: (_) => vm.toggleTheme(),
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: vm.language,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
              ],
              onChanged: (v) {
                if (v != null) vm.setLanguage(v);
              },
            ),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text('Security settings'),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Settings'), // remove title
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // custom back button
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 1000;
            if (wide) {
              return Row(children: [Expanded(child: menu)]);
            }
            return ListView(children: [menu]);
          },
        ),
      ),
    );
  }
}
