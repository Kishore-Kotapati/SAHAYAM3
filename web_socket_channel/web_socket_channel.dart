import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum WebSocketState {
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketChannel {
  WebSocket? _webSocket;
  String _url;
  Map<String, String>? _headers;
  
  WebSocketState _state = WebSocketState.disconnected;
  StreamController<String>? _messageController;
  StreamController<WebSocketState>? _stateController;
  
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  Duration _reconnectDelay = const Duration(seconds: 5);
  Duration _heartbeatInterval = const Duration(seconds: 30);
  
  // Constructor
  WebSocketChannel(this._url, {Map<String, String>? headers}) {
    _headers = headers;
    _messageController = StreamController<String>.broadcast();
    _stateController = StreamController<WebSocketState>.broadcast();
  }

  // Getters
  WebSocketState get state => _state;
  Stream<String> get messages => _messageController!.stream;
  Stream<WebSocketState> get stateChanges => _stateController!.stream;
  bool get isConnected => _state == WebSocketState.connected;

  // Connect to WebSocket
  Future<void> connect() async {
    if (_state == WebSocketState.connected || _state == WebSocketState.connecting) {
      return;
    }

    _setState(WebSocketState.connecting);
    _shouldReconnect = true;

    try {
      _webSocket = await WebSocket.connect(_url, headers: _headers);
      _reconnectAttempts = 0;
      _setState(WebSocketState.connected);
      
      _setupListeners();
      _startHeartbeat();
      
      print('WebSocket connected to: $_url');
    } catch (e) {
      print('WebSocket connection error: $e');
      _setState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _cancelTimers();
    
    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }
    
    _setState(WebSocketState.disconnected);
    print('WebSocket disconnected');
  }

  // Send message
  void send(String message) {
    if (_state == WebSocketState.connected && _webSocket != null) {
      _webSocket!.add(message);
    } else {
      print('Cannot send message: WebSocket not connected');
    }
  }

  // Send JSON message
  void sendJson(Map<String, dynamic> data) {
    try {
      String jsonMessage = jsonEncode(data);
      send(jsonMessage);
    } catch (e) {
      print('Error encoding JSON message: $e');
    }
  }

  // Setup WebSocket listeners
  void _setupListeners() {
    _webSocket!.listen(
      (data) {
        String message = data.toString();
        _messageController!.add(message);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _setState(WebSocketState.error);
        _scheduleReconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        _setState(WebSocketState.disconnected);
        if (_shouldReconnect) {
          _scheduleReconnect();
        }
      },
    );
  }

  // Set WebSocket state
  void _setState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController!.add(_state);
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached or reconnection disabled');
      return;
    }

    _reconnectAttempts++;
    Duration delay = Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);
    
    print('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds} seconds');
    
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect) {
        connect();
      }
    });
  }

  // Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_state == WebSocketState.connected) {
        send('ping');
      }
    });
  }

  // Cancel all timers
  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Update connection settings
  void updateReconnectionSettings({
    int? maxAttempts,
    Duration? delay,
    Duration? heartbeatInterval,
  }) {
    if (maxAttempts != null) _maxReconnectAttempts = maxAttempts;
    if (delay != null) _reconnectDelay = delay;
    if (heartbeatInterval != null) {
      _heartbeatInterval = heartbeatInterval;
      if (_state == WebSocketState.connected) {
        _heartbeatTimer?.cancel();
        _startHeartbeat();
      }
    }
  }

  // Reset reconnection attempts
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController?.close();
    _stateController?.close();
    _messageController = null;
    _stateController = null;
  }
}

// Usage example and helper class
class WebSocketManager {
  static WebSocketChannel? _instance;
  
  static WebSocketChannel getInstance(String url, {Map<String, String>? headers}) {
    _instance ??= WebSocketChannel(url, headers: headers);
    return _instance!;
  }
  
  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }
}