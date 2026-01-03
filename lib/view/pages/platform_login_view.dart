import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_model/connects_view_model.dart';

class PlatformLoginView extends StatefulWidget {
  final String platformName;

  const PlatformLoginView({super.key, required this.platformName});

  @override
  State<PlatformLoginView> createState() => _PlatformLoginViewState();
}

class _PlatformLoginViewState extends State<PlatformLoginView> {
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      // NOTE: MT4/MT5 direct authentication requires broker APIs or a bridge/EA.
      // For now we store only the fact that the user connected MT4/MT5 in the DB
      // (platforms + user_platforms). Credentials are *not* stored.
      await context.read<ConnectsViewModel>().connect(widget.platformName);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect ${widget.platformName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account / Login',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverCtrl,
              decoration: const InputDecoration(
                labelText: 'Server (Broker)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: This step saves the platform connection (MT4/MT5) in your database.\n'
              'The next step is the real integration via a bridge/EA or broker API.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            if (_err != null) ...[
              const SizedBox(height: 12),
              Text(_err!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _connect,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
