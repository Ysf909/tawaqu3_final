import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tick.dart';

class TickWsService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Tick>.broadcast();

  Stream<Tick> get ticks$ => _controller.stream;

  void connect(String wsUrl) {
    disconnect();
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (msg) {
        try {
          final data = jsonDecode(msg as String);
          if (data is Map<String, dynamic> && data['type'] == 'tick') {
            _controller.add(Tick.fromJson(data));
          }
        } catch (_) {
          // ignore malformed
        }
      },
      onError: (e) {},
      onDone: () {},
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
