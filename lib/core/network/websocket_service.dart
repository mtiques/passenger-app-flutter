import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService {
  WebSocketChannel? _channel;
  final _logger = Logger();
  final _controllers = <String, StreamController<dynamic>>{};

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Conectar al WebSocket del backend Spring Boot
  Future<void> connect(String token) async {
    try {
      _logger.i('🔌 Connecting to WebSocket: ${AppConfig.wsUrl}');

      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsUrl}?token=$token'),
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Escuchar mensajes
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _logger.i('✅ WebSocket connected successfully');
    } catch (e) {
      _logger.e('❌ WebSocket connection error: $e');
      _scheduleReconnect(token);
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String?;

      if (event != null && _controllers.containsKey(event)) {
        _controllers[event]!.add(data['data']);
        _logger.d('📨 WebSocket message received: $event');
      }
    } catch (e) {
      _logger.e('❌ Error parsing WebSocket message: $e');
    }
  }

  void _onError(error) {
    _logger.e('❌ WebSocket error: $error');
    _isConnected = false;
  }

  void _onDone() {
    _logger.w('⚠️ WebSocket connection closed');
    _isConnected = false;
  }

  void _scheduleReconnect(String token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('❌ Max reconnection attempts reached');
      return;
    }

    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _logger.i('🔄 Reconnecting in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect(token);
    });
  }

  // Suscribirse a eventos específicos
  Stream<T> on<T>(String event) {
    if (!_controllers.containsKey(event)) {
      _controllers[event] = StreamController<T>.broadcast();
    }
    return _controllers[event]!.stream.cast<T>();
  }

  // Emitir eventos al servidor
  void emit(String event, dynamic data) {
    if (_isConnected && _channel != null) {
      final message = jsonEncode({
        'event': event,
        'data': data,
      });
      _channel!.sink.add(message);
      _logger.d('📤 WebSocket message sent: $event');
    } else {
      _logger.w('⚠️ Cannot emit, WebSocket not connected');
    }
  }

  // Desconectar
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controllers.forEach((key, controller) => controller.close());
    _controllers.clear();
    _isConnected = false;
    _logger.i('🔌 WebSocket disconnected');
  }

  bool get isConnected => _isConnected;
}
