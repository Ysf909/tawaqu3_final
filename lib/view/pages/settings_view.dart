import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    final menu = CardContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Menu'),
        const ListTile(leading: CircleAvatar(child: Text('JD')), title: Text('John Doe'), subtitle: Text('john.doe@email.com')),
        const Divider(),
        const ListTile(leading: Icon(Icons.link), title: Text('Connects')),
        const ListTile(leading: Icon(Icons.notifications), title: Text('Notifications')),
        const ListTile(leading: Icon(Icons.history), title: Text('History')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: (){}, child: const Text('LOGOUT')),
      ],
    ));

    final settings = CardContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Settings'),
        SwitchListTile(title: const Text('Dark Mode'), value: vm.isDark, onChanged: (_)=> vm.toggleTheme()),
        ListTile(
          title: const Text('Language'),
          trailing: DropdownButton<String>(value: vm.language, items: const [
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
          ], onChanged: (v){ if (v!=null) vm.setLanguage(v); }),
        ),
        const ListTile(title: Text('Privacy'), subtitle: Text('Security settings')),
        const ListTile(title: Text('Logout'), subtitle: Text('Sign out of account')),
      ],
    ));

    final connects = CardContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Connects'),
        SwitchListTile(title: const Text('MT5 (MetaTrader 5)'), value: vm.mt5Connected, onChanged: vm.setMt5),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.add), label: const Text('ADD CONNECTION')),
      ],
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Navigation & Settings')),
      body: LayoutBuilder(builder: (context, c){
        final wide = c.maxWidth > 1000;
        if (wide) return Row(children: [Expanded(child: menu), Expanded(child: settings), Expanded(child: connects)]);
        return ListView(children: [menu, settings, connects]);
      }),
    );
  }
}

