// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  
  SocketService._internal();
  
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }
  
  // IMPORTANT: Update this URL based on your platform
  static const String serverUrl = 'http://localhost:3000';
  // For Android emulator: 'http://10.0.2.2:3000'
  // For iOS simulator: 'http://localhost:3000' 
  // For physical device: 'http://YOUR_COMPUTER_IP:3000'
  
  void connect() {
    try {
      print('Attempting to connect to: $serverUrl');
      
      _socket = IO.io(serverUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try both transports
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setTimeout(20000)
          .build()
      );
      
      _socket!.onConnect((_) {
        print('✅ Connected to server: ${_socket!.id}');
      });
      
      _socket!.onDisconnect((_) {
        print('❌ Disconnected from server');
      });
      
      _socket!.onConnectError((error) {
        print('🔴 Connection error: $error');
      });
      
      _socket!.onError((error) {
        print('🔴 Socket error: $error');
      });
      
      _socket!.onReconnect((data) {
        print('🔄 Reconnected to server');
      });
      
      _socket!.onReconnectError((error) {
        print('🔴 Reconnection failed: $error');
      });
      
    } catch (e) {
      print('🔴 Socket connection failed: $e');
    }
  }
  
  void disconnect() {
    print('Disconnecting from server...');
    _socket?.disconnect();
    _socket = null;
  }
  
  void joinRoom(String roomId) {
    if (_socket?.connected == true) {
      _socket?.emit('join_room', roomId);
      print('📨 Joined room: $roomId');
    } else {
      print('❌ Cannot join room - not connected');
    }
  }
  
  void sendMessage({
    required String roomId,
    required String text,
    required String sender,
    String? mood,
  }) {
    if (_socket?.connected == true) {
      final messageData = {
        'roomId': roomId,
        'text': text,
        'sender': sender,
        'timestamp': DateTime.now().toIso8601String(),
        'mood': mood,
      };
      
      _socket?.emit('send_message', messageData);
      print('📨 Message sent: $text');
    } else {
      print('❌ Cannot send message - not connected');
    }
  }
  
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _socket?.on('receive_message', (data) {
      print('📨 Message received: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }
  
  void onUserJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_joined', (data) {
      print('👤 User joined: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }
  
  void onUserTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_typing', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }
  
  bool get isConnected => _socket?.connected ?? false;
  
  String? get socketId => _socket?.id;
  
  // Add method to test connection
  void testConnection() {
    print('Testing connection...');
    print('Socket exists: ${_socket != null}');
    print('Socket connected: ${_socket?.connected}');
    print('Socket ID: ${_socket?.id}');
    print('Server URL: $serverUrl');
  }
}