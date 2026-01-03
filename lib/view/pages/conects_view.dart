import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repository/platform_repository.dart';
import '../../view_model/connects_view_model.dart';
import 'platform_login_view.dart';

class ConnectsView extends StatefulWidget {
  const ConnectsView({super.key});

  @override
  State<ConnectsView> createState() => _ConnectsViewState();
}

class _ConnectsViewState extends State<ConnectsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectsViewModel>().load();
    });
  }

  Future<void> _openPlatformLogin(String name) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlatformLoginView(platformName: name)),
    );
    if (!mounted) return;
    await context.read<ConnectsViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Connections')),
          body: RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(
                  'Add a platform',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...PlatformRepository.supportedPlatforms.map((p) {
                  final isConnected = vm.connected.contains(p);
                  return _PlatformCard(
                    name: p,
                    connected: isConnected,
                    loading: vm.loading,
                    onConnect: () => _openPlatformLogin(p),
                    onDisconnect: () => vm.disconnect(p),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'Connected platforms',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (vm.connected.isEmpty)
                  const Text('No platforms connected yet.'),
                if (vm.connected.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: vm.connected
                        .map((p) => Chip(label: Text(p)))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final bool connected;
  final bool loading;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _PlatformCard({
    required this.name,
    required this.connected,
    required this.loading,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  connected ? 'Connected' : 'Not connected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!connected)
            ElevatedButton(
              onPressed: loading ? null : onConnect,
              child: const Text('Connect'),
            )
          else
            OutlinedButton(
              onPressed: loading ? null : onDisconnect,
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }
}
