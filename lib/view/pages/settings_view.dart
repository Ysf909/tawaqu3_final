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
      final menu = CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Settings'),
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
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Arabic',
                    child: Text('Arabic'),
                  ),
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
        
    
      return menu;
    }
  }