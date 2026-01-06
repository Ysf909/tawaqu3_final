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

          const Divider(height: 24),

          const ListTile(
            title: Text('Privacy'),
            subtitle: Text('Security settings'),
          ),

          SwitchListTile(
            title: const Text('Hide my profit on Top Traders'),
            subtitle: const Text(
              'Your profile stays visible, but profit will be hidden from other users.',
            ),
            value: vm.hideProfit,
            onChanged: vm.privacyLoading ? null : (v) => vm.setHideProfit(v),
          ),

          if (vm.privacyLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(),
            ),

          if (vm.privacyError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                vm.privacyError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 1000;
            if (wide) return Row(children: [Expanded(child: menu)]);
            return ListView(children: [menu]);
          },
        ),
      ),
    );
  }
}
