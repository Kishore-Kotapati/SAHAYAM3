const { Server } = require('socket.io');
const { v4: uuidv4 } = require('uuid');

let io;
const activeUsers = new Map();
const chatRooms = new Map();

export default function handler(req, res) {
  if (!res.socket.server.io) {
    console.log('🔌 Initializing Socket.IO server...');
    
    io = new Server(res.socket.server, {
      cors: {
        origin: process.env.NODE_ENV === 'production' 
          ? [process.env.FRONTEND_URL, 'https://your-app.vercel.app']
          : ['http://localhost:5000', 'http://localhost:8080', 'http://127.0.0.1:8080'],
        methods: ["GET", "POST"],
        credentials: true
      },
      transports: ['websocket', 'polling'],
      allowEIO3: true
    });

    io.on('connection', (socket) => {
      console.log('✅ Client connected:', socket.id);

      // Handle user authentication/registration
      socket.on('user_join', (data) => {
        const { userId, username, sessionId } = data;
        
        activeUsers.set(socket.id, {
          userId,
          username,
          sessionId,
          joinedAt: new Date().toISOString()
        });

        socket.userId = userId;
        socket.sessionId = sessionId;
        
        console.log(`👤 User ${username} joined with session ${sessionId}`);
        
        socket.emit('user_joined', {
          success: true,
          message: 'Connected to MoodSync',
          sessionId
        });
      });

      // Handle mood updates
      socket.on('mood_update', (data) => {
        const { userId, mood, scale } = data;
        
        // Broadcast mood update to relevant connections
        socket.broadcast.emit('mood_broadcast', {
          userId,
          mood,
          scale,
          timestamp: new Date().toISOString()
        });

        console.log(`🎭 Mood update from ${userId}: ${mood} (${scale}/10)`);
      });

      // Handle real-time chat messages
      socket.on('send_message', (data) => {
        const { message, sessionId, userId } = data;
        const messageId = uuidv4();

        const messageData = {
          id: messageId,
          message,
          userId,
          sessionId,
          timestamp: new Date().toISOString(),
          type: 'user'
        };

        // Echo back to sender
        socket.emit('message_sent', messageData);

        console.log(`💬 Message from ${userId}: ${message.substring(0, 50)}...`);
      });

      // Handle AI response broadcasting
      socket.on('ai_response', (data) => {
        const { response, sessionId, userId } = data;
        const messageId = uuidv4();

        const responseData = {
          id: messageId,
          message: response,
          sessionId,
          timestamp: new Date().toISOString(),
          type: 'ai'
        };

        socket.emit('ai_message', responseData);
        
        console.log(`🤖 AI response to ${userId}: ${response.substring(0, 50)}...`);
      });

      // Handle typing indicators
      socket.on('typing_start', (data) => {
        const { sessionId } = data;
        socket.broadcast.emit('user_typing', { sessionId, typing: true });
      });

      socket.on('typing_stop', (data) => {
        const { sessionId } = data;
        socket.broadcast.emit('user_typing', { sessionId, typing: false });
      });

      // Handle support room joining
      socket.on('join_support', (data) => {
        const { roomId } = data;
        socket.join(`support_${roomId}`);
        
        socket.emit('support_joined', {
          success: true,
          roomId,
          message: 'Connected to support chat'
        });

        console.log(`🆘 User joined support room: ${roomId}`);
      });

      // Handle emergency alerts
      socket.on('emergency_alert', (data) => {
        const { userId, severity, message } = data;
        
        // Broadcast to support staff (you'd implement this logic)
        io.emit('emergency_notification', {
          userId,
          severity,
          message,
          timestamp: new Date().toISOString()
        });

        console.log(`🚨 Emergency alert from ${userId}: ${severity}`);
      });

      // Handle wellness check-ins
      socket.on('wellness_checkin', (data) => {
        const { userId, status, notes } = data;
        
        socket.broadcast.emit('wellness_update', {
          userId,
          status,
          notes,
          timestamp: new Date().toISOString()
        });

        console.log(`✅ Wellness check-in from ${userId}: ${status}`);
      });

      // Handle session heartbeat
      socket.on('heartbeat', () => {
        socket.emit('heartbeat_ack', {
          timestamp: new Date().toISOString(),
          status: 'connected'
        });
      });

      // Handle disconnection
      socket.on('disconnect', (reason) => {
        const user = activeUsers.get(socket.id);
        if (user) {
          console.log(`👋 User ${user.username} disconnected: ${reason}`);
          activeUsers.delete(socket.id);
          
          // Notify others about user leaving
          socket.broadcast.emit('user_left', {
            userId: user.userId,
            username: user.username,
            reason
          });
        }
      });

      // Handle connection errors
      socket.on('error', (error) => {
        console.error('❌ Socket error:', error);
        socket.emit('connection_error', {
          error: 'Connection error occurred',
          timestamp: new Date().toISOString()
        });
      });
    });

    // Store io instance
    res.socket.server.io = io;
    
    console.log('🚀 Socket.IO server initialized successfully');
  }

  res.end();
}