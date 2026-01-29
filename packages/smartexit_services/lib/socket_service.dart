import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'config_service.dart';
import 'storage_service.dart';

typedef SocketCallback = void Function(dynamic data);

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  SocketService._();

  io.Socket? _socket;
  bool _isConnected = false;

  // Event callbacks
  final Map<String, List<SocketCallback>> _listeners = {};

  // Stream controllers for reactive updates
  final _cartUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _exitDecisionController = StreamController<Map<String, dynamic>>.broadcast();
  final _exitRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _newOrderController = StreamController<Map<String, dynamic>>.broadcast();
  final _fraudAlertController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Streams for listeners
  Stream<Map<String, dynamic>> get cartUpdates => _cartUpdateController.stream;
  Stream<Map<String, dynamic>> get exitDecisions => _exitDecisionController.stream;
  Stream<Map<String, dynamic>> get exitRequests => _exitRequestController.stream;
  Stream<Map<String, dynamic>> get newOrders => _newOrderController.stream;
  Stream<Map<String, dynamic>> get fraudAlerts => _fraudAlertController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Connect to Socket.io server
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final token = await StorageService.getAccessToken();
    if (token == null) return;

    _socket = io.io(
      ConfigService.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  void _setupListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      print('Socket disconnected');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      print('Socket reconnected');
    });

    // Cart updates
    _socket!.on('cart:updated', (data) {
      _cartUpdateController.add(Map<String, dynamic>.from(data));
      _notifyListeners('cart:updated', data);
    });

    // Exit decision (for customers)
    _socket!.on('exit:decision', (data) {
      _exitDecisionController.add(Map<String, dynamic>.from(data));
      _notifyListeners('exit:decision', data);
    });

    // Exit request (for security)
    _socket!.on('exit:request', (data) {
      _exitRequestController.add(Map<String, dynamic>.from(data));
      _notifyListeners('exit:request', data);
    });

    // New order (for admin)
    _socket!.on('order:new', (data) {
      _newOrderController.add(Map<String, dynamic>.from(data));
      _notifyListeners('order:new', data);
    });

    // Fraud alert (for admin)
    _socket!.on('fraud:alert', (data) {
      _fraudAlertController.add(Map<String, dynamic>.from(data));
      _notifyListeners('fraud:alert', data);
    });
  }

  void _notifyListeners(String event, dynamic data) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback(data);
      }
    }
  }

  /// Add event listener
  void on(String event, SocketCallback callback) {
    _listeners.putIfAbsent(event, () => []);
    _listeners[event]!.add(callback);
  }

  /// Remove event listener
  void off(String event, SocketCallback callback) {
    _listeners[event]?.remove(callback);
  }

  /// Emit event to server
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Disconnect from server
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
    _cartUpdateController.close();
    _exitDecisionController.close();
    _exitRequestController.close();
    _newOrderController.close();
    _fraudAlertController.close();
    _connectionController.close();
  }

  /// Reconnect with new token (after refresh)
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }
}
