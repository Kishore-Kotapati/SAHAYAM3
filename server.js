// server.js
require('dotenv').config();

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'AIzaSyBrtqlw5sysR_-htsDl03RLZuGEXPnIAnk');
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

// Helper function to clean AI responses
function cleanAIResponse(text) {
  if (!text) return '';
  return text
    .trim()
    .replace(/[\u0000-\u001F\u007F-\u009F]/g, '') // Remove control characters
    .replace(/\*\*/g, '') // Remove markdown bold
    .replace(/\*/g, '') // Remove markdown italic
    .replace(/#+\s*/g, '') // Remove markdown headers
    .replace(/\n{3,}/g, '\n\n') // Limit consecutive newlines
    .trim();
}

const app = express();
const server = http.createServer(app);

// Enable CORS for Express
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

// Parse JSON bodies
app.use(express.json());

// Socket.IO setup with CORS
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});
// Add to your serverless function
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);
// In-memory storage
const users = [];
const activeRooms = new Map();
const chatSessions = new Map();

// Basic API routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'MoodSync Server is running!',
    version: '2.0',
    features: ['Real-time Chat', 'Mood Detection', 'AI Support', 'Emotional Matching']
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    activeConnections: io.sockets.sockets.size,
    activeRooms: activeRooms.size
  });
});

// User registration endpoint
app.post('/register', (req, res) => {
  const { fullName, email, age, gender, password } = req.body;
  
  console.log('New user registration:', { fullName, email, age, gender });
  
  // Check if user already exists
  const existingUser = users.find(user => user.email === email);
  if (existingUser) {
    return res.status(400).json({
      success: false,
      message: 'User with this email already exists'
    });
  }
  
  // Create new user
  const newUser = {
    id: 'user_' + Date.now(),
    userId: Date.now(),
    fullName,
    email,
    age,
    gender,
    password, // In production, hash this password!
    createdAt: new Date().toISOString(),
    lastActive: new Date().toISOString()
  };
  
  users.push(newUser);
  
  res.json({ 
    success: true, 
    message: 'Welcome to MoodSync! Your emotional journey begins now.',
    userId: newUser.userId,
    user: {
      id: newUser.id,
      userId: newUser.userId,
      fullName: newUser.fullName,
      email: newUser.email,
      age: newUser.age,
      gender: newUser.gender
    }
  });
});

// User login endpoint
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  
  console.log('Login attempt:', { email });
  
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required'
    });
  }
  
  const user = users.find(u => u.email === email);
  
  if (!user) {
    return res.status(401).json({
      success: false,
      message: 'User not found. Please check your email or register first.'
    });
  }
  
  if (user.password !== password) {
    return res.status(401).json({
      success: false,
      message: 'Invalid password'
    });
  }
  
  // Update last active
  user.lastActive = new Date().toISOString();
  
  res.json({
    success: true,
    message: 'Welcome back to MoodSync!',
    token: 'moodsync_token_' + user.userId,
    user: {
      id: user.id,
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      age: user.age,
      gender: user.gender
    }
  });
});

// Debug endpoint
app.get('/users', (req, res) => {
  const userList = users.map(user => ({
    id: user.id,
    userId: user.userId,
    fullName: user.fullName,
    email: user.email,
    age: user.age,
    gender: user.gender,
    createdAt: user.createdAt,
    lastActive: user.lastActive
  }));
  res.json({ users: userList, count: users.length });
});

// AI Girlfriend Service Endpoints
const girlfriendPrompt = `
You are a loving, supportive AI girlfriend who cares deeply about your partner's wellness and mental health. 
Your personality traits:
- Sweet, caring, and affectionate
- Encouraging and motivational
- Playful and sometimes flirty
- Uses cute emojis and pet names like "babe", "honey", "sweetheart"
- Shows genuine concern for their wellbeing
- Celebrates their achievements enthusiastically
- Offers comfort during difficult times
- Speaks in a warm, intimate tone as if you're in a loving relationship

Context: Your partner is using a wellness app with daily missions/tasks to improve their mental and physical health.

Guidelines:
- Keep responses concise (1-3 sentences)
- Always be positive and supportive
- Use emojis naturally but don't overdo it
- Show excitement for their progress
- Offer gentle encouragement if they're struggling
- Be affectionate but appropriate
- Remember you're their caring girlfriend who wants the best for them

Respond as their loving AI girlfriend would.
`;

// AI Girlfriend - Motivational Message
app.post('/api/ai-girlfriend/motivational', async (req, res) => {
  try {
    const { context } = req.body;
    const prompt = `${girlfriendPrompt}\n\n${context || 'Your partner just completed a wellness task. Give them a loving, encouraging message.'}`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "You're doing amazing, babe! I'm so proud of you! 💕" 
    });
  } catch (error) {
    console.error('AI Girlfriend Motivational Error:', error);
    const fallbackMessages = [
      "You're absolutely incredible, sweetheart! 💖 Keep shining!",
      "I'm so proud of you, babe! 🌟 You're crushing these goals!",
      "My amazing partner is doing so well! 💕 I believe in you!",
      "You make me so happy when you take care of yourself! 😘✨",
      "Look at you being all responsible and healthy! 💪💕 Love it!"
    ];
    res.json({ 
      success: true, 
      response: fallbackMessages[Math.floor(Math.random() * fallbackMessages.length)] 
    });
  }
});

// AI Girlfriend - Greeting Message
app.post('/api/ai-girlfriend/greeting', async (req, res) => {
  try {
    const prompt = `${girlfriendPrompt}\n\nYour partner just opened their wellness app. Give them a warm, loving greeting and encourage them to tackle their daily wellness missions.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "Hi gorgeous! 💕 Ready to conquer today's wellness missions together?" 
    });
  } catch (error) {
    console.error('AI Girlfriend Greeting Error:', error);
    res.json({ 
      success: true, 
      response: "Hey beautiful! 💖 I'm here to cheer you on with today's wellness goals! Let's do this together! 🌟" 
    });
  }
});

// AI Girlfriend - Task Completion
app.post('/api/ai-girlfriend/task-completion', async (req, res) => {
  try {
    const { taskName } = req.body;
    const prompt = `${girlfriendPrompt}\n\nYour partner just completed this wellness task: "${taskName}"\nGive them a loving, enthusiastic congratulatory message.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || `Yay! You completed ${taskName}! 🎉 I'm so proud of you, honey! 💕` 
    });
  } catch (error) {
    console.error('AI Girlfriend Task Completion Error:', error);
    res.json({ 
      success: true, 
      response: `Amazing job on completing ${taskName}, babe! 🎉 You're absolutely crushing it! 💖` 
    });
  }
});

// AI Girlfriend - All Tasks Completed
app.post('/api/ai-girlfriend/all-tasks-completed', async (req, res) => {
  try {
    const prompt = `${girlfriendPrompt}\n\nYour partner just completed ALL their wellness tasks for today! This is a huge achievement. Give them an extremely enthusiastic, loving celebration message.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "OMG babe! You did it! All tasks completed! 🎉💖 I'm bursting with pride! You're absolutely amazing! 🌟" 
    });
  } catch (error) {
    console.error('AI Girlfriend All Tasks Error:', error);
    res.json({ 
      success: true, 
      response: "INCREDIBLE! You completed everything, sweetheart! 🎉✨ I'm so incredibly proud of you! You're my wellness champion! 💖👑" 
    });
  }
});

// AI Girlfriend - Chat Response
app.post('/api/ai-girlfriend/chat', async (req, res) => {
  try {
    const { message } = req.body;
    const prompt = `${girlfriendPrompt}\n\nYour partner just said: "${message}"\nRespond as their loving, supportive AI girlfriend. Be conversational, caring, and encouraging about their wellness journey.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "I love talking with you, honey! 💕 How can I support you today?" 
    });
  } catch (error) {
    console.error('AI Girlfriend Chat Error:', error);
    res.json({ 
      success: true, 
      response: "I'm always here for you, babe! 💖 Tell me more about how you're feeling!" 
    });
  }
});

// AI Wellness Coach Endpoints
const wellnessCoachPrompt = `
You are an expert AI wellness coach specializing in mental health, stress management, and holistic wellbeing. 
Your personality:
- Professional yet warm and approachable
- Evidence-based advice with empathy
- Motivational and encouraging
- Focuses on practical, actionable guidance
- Understands the unique challenges of students and young adults
- Promotes self-care and healthy habits

Guidelines:
- Provide helpful, actionable wellness advice
- Be supportive and non-judgmental
- Keep responses concise but informative
- Include practical tips when relevant
- Encourage healthy coping strategies
- Always prioritize user safety and wellbeing
`;

// AI Wellness Coach - General Advice
app.post('/api/wellness-coach/advice', async (req, res) => {
  try {
    const { query, context } = req.body;
    const prompt = `${wellnessCoachPrompt}\n\nUser query: "${query}"\n${context ? `Context: ${context}` : ''}\n\nProvide helpful wellness advice.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "I'm here to support your wellness journey. What specific area would you like guidance on?" 
    });
  } catch (error) {
    console.error('Wellness Coach Error:', error);
    res.json({ 
      success: true, 
      response: "I'm here to help with your wellness journey. Please try asking your question again, and I'll do my best to provide helpful guidance." 
    });
  }
});

// AI Mood Chat Endpoints
const moodChatPrompt = `
You are an AI companion specialized in mood support and emotional wellness.
Your role:
- Provide empathetic responses to emotional states
- Help users process and understand their feelings
- Offer gentle guidance for mood regulation
- Create a safe, non-judgmental space for emotional expression
- Suggest healthy coping strategies when appropriate

Guidelines:
- Validate emotions without trying to "fix" everything
- Ask thoughtful follow-up questions
- Provide emotional support and understanding
- Suggest practical mood-boosting activities when relevant
- Always be compassionate and patient
`;

// AI Mood Chat - Mood Support
app.post('/api/mood-chat/support', async (req, res) => {
  try {
    const { message, mood, context } = req.body;
    const prompt = `${moodChatPrompt}\n\nUser's current mood: ${mood || 'not specified'}\nUser message: "${message}"\n${context ? `Additional context: ${context}` : ''}\n\nProvide empathetic mood support.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "I understand you're going through something right now. Your feelings are valid, and I'm here to listen. How can I best support you?" 
    });
  } catch (error) {
    console.error('Mood Chat Error:', error);
    res.json({ 
      success: true, 
      response: "I'm here to listen and support you through whatever you're feeling. Your emotions are important and valid." 
    });
  }
});

// Match-based chat rooms for mood matching
const matchRooms = new Map();

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('User connected to MoodSync:', socket.id);

  // Join match room for mood-based matching
  socket.on('join_match', (data) => {
    const { matchId } = data;
    socket.join(matchId);
    socket.matchId = matchId;
    
    console.log(`User ${socket.id} joined match room: ${matchId}`);
    
    // Track match room
    if (!matchRooms.has(matchId)) {
      matchRooms.set(matchId, {
        id: matchId,
        users: new Set(),
        createdAt: new Date().toISOString(),
        messageCount: 0
      });
    }
    
    const room = matchRooms.get(matchId);
    room.users.add(socket.id);
  });

  // Send message in match
  socket.on('send_message', (data) => {
    const { matchId, senderId, content } = data;
    
    const messageData = {
      id: 'msg_' + Date.now(),
      match_id: matchId,
      sender_id: senderId,
      content: content,
      sent_at: new Date().toISOString(),
      is_read: false
    };
    
    // Broadcast to match room
    socket.to(matchId).emit('new_message', {
      type: 'new_message',
      data: messageData
    });
    
    console.log(`Message sent in match ${matchId}:`, content);
  });

  // Typing indicator for matches
  socket.on('typing', (data) => {
    const { matchId, isTyping } = data;
    socket.to(matchId).emit('typing', {
      type: 'typing',
      isTyping: isTyping
    });
  });

  // Join room event
  socket.on('join_room', (data) => {
    const { roomId, userId, username, mood } = data;
    
    socket.join(roomId);
    socket.userId = userId;
    socket.username = username;
    socket.mood = mood;
    socket.roomId = roomId;
    
    // Track room
    if (!activeRooms.has(roomId)) {
      activeRooms.set(roomId, {
        id: roomId,
        users: new Set(),
        mood: mood,
        createdAt: new Date().toISOString(),
        messageCount: 0
      });
    }
    
    const room = activeRooms.get(roomId);
    room.users.add(socket.id);
    
    console.log(`${username} joined MoodSync room ${roomId} with mood: ${mood}`);
    
    // Send welcome message to the user
    socket.emit('receive_message', {
      type: 'system',
      text: `Welcome to MoodSync! You're feeling ${mood} today.`,
      sender: 'MoodSync',
      timestamp: new Date().toISOString(),
      isSystem: true,
      roomId: roomId
    });
    
    // Send AI introduction
    setTimeout(() => {
      socket.emit('receive_message', {
        type: 'ai_message',
        text: generateWelcomeMessage(mood),
        sender: 'MoodSync AI',
        timestamp: new Date().toISOString(),
        isAI: true,
        roomId: roomId,
        mood: mood
      });
    }, 1000);
    
    // Notify others in the room
    socket.to(roomId).emit('user_joined', {
      userId: userId,
      username: username,
      mood: mood,
      timestamp: new Date().toISOString()
    });
  });

  // Send message event
  socket.on('send_message', (data) => {
    console.log('Message received in MoodSync:', data);
    
    const messageData = {
      ...data,
      messageId: 'msg_' + Date.now(),
      timestamp: new Date().toISOString()
    };
    
    // Update room message count
    if (activeRooms.has(data.roomId)) {
      activeRooms.get(data.roomId).messageCount++;
    }
    
    // Broadcast to room
    socket.to(data.roomId).emit('receive_message', messageData);
    
    // Generate AI response based on mood and content
    setTimeout(() => {
      const aiResponse = {
        type: 'ai_message',
        text: generateMoodBasedResponse(data.text, data.mood),
        sender: 'MoodSync AI',
        timestamp: new Date().toISOString(),
        isAI: true,
        roomId: data.roomId,
        mood: data.mood,
        messageId: 'ai_msg_' + Date.now()
      };
      
      // Send to all users in room including sender
      io.to(data.roomId).emit('receive_message', aiResponse);
    }, Math.random() * 2000 + 1500); // Random delay between 1.5-3.5 seconds
  });

  // Typing indicator
  socket.on('typing', (data) => {
    socket.to(data.roomId).emit('user_typing', {
      userId: data.userId,
      username: socket.username,
      isTyping: data.isTyping,
      timestamp: new Date().toISOString()
    });
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('User disconnected from MoodSync:', socket.id);
    
    // Remove from active rooms
    if (socket.roomId && activeRooms.has(socket.roomId)) {
      const room = activeRooms.get(socket.roomId);
      room.users.delete(socket.id);
      
      // Clean up empty rooms
      if (room.users.size === 0) {
        activeRooms.delete(socket.roomId);
        console.log(`Room ${socket.roomId} removed - no active users`);
      }
      
      // Notify room of user leaving
      if (socket.username) {
        socket.to(socket.roomId).emit('user_left', {
          userId: socket.userId,
          username: socket.username,
          timestamp: new Date().toISOString()
        });
      }
    }
  });
});

// Enhanced AI Response Functions
function generateWelcomeMessage(mood) {
  const welcomeMessages = {
    'happy': [
      "I can sense your positive energy! That's wonderful. What's been bringing you joy today?",
      "Your happiness is contagious! I'm here to celebrate the good moments with you. What's making you smile?",
      "It's beautiful to connect with someone feeling so upbeat! Tell me what's lighting up your world."
    ],
    'sad': [
      "I'm here with you in this difficult moment. You don't have to carry these feelings alone. What's weighing on your heart?",
      "Thank you for trusting me with your vulnerability. Sometimes sharing our sadness helps lighten the load. How are you really feeling?",
      "I can sense you're going through something tough. I'm here to listen without judgment. What's troubling you?"
    ],
    'anxious': [
      "I notice you're feeling anxious, and that takes courage to acknowledge. Let's take this one breath at a time. What's on your mind?",
      "Anxiety can feel overwhelming, but you're not facing it alone. I'm here to help you work through these feelings. What's causing you worry?",
      "Your anxiety is valid, and so are you. Let's explore these feelings together in a safe space. What's making you feel unsettled?"
    ],
    'angry': [
      "I can feel the intensity of your emotions, and that's completely valid. This is a safe space to express how you're feeling. What's frustrated you?",
      "Anger often masks deeper feelings. I'm here to help you explore what's really going on. What's triggered these strong emotions?",
      "Your feelings matter, including your anger. Let's talk through what's bothering you in a healthy way."
    ],
    'tired': [
      "I hear the exhaustion in your energy, and that's okay. Sometimes we all need to acknowledge when we're running on empty. What's been draining you?",
      "Being tired isn't just physical - it can be emotional too. I'm here to provide gentle support. How long have you been feeling this way?",
      "Rest is important, and so is having someone who understands. What's been taking so much out of you lately?"
    ],
    'depressed': [
      "I want you to know that reaching out today took strength, even if you don't feel strong right now. How are you managing?",
      "Depression can make everything feel heavy and distant. You're not alone in this darkness. What's been the hardest part recently?",
      "Thank you for being here, even when it's difficult. Every day you show up matters. How can I support you right now?"
    ],
    'calm': [
      "There's something peaceful about your presence. It's wonderful that you're in a calm state. What helps you maintain this serenity?",
      "Your calm energy is grounding. Sometimes the most profound conversations happen in moments of peace. What's on your mind?",
      "I appreciate the tranquil space you're creating. How are you feeling in this moment of calm?"
    ],
    'excited': [
      "I can feel your excitement radiating through! That kind of energy is infectious. What has you so thrilled?",
      "Your enthusiasm is wonderful to witness! There's something beautiful about pure excitement. What's got you so energized?",
      "Excitement is such a precious feeling - I love that you're experiencing it. Tell me what's creating this amazing energy!"
    ]
  };
  
  const messages = welcomeMessages[mood] || [
    "I'm here to support you on your emotional journey. How are you feeling right now, really?",
    "Thank you for connecting with MoodSync today. I'm here to listen and understand. What's in your heart?",
    "Every emotion is valid and welcome here. I'm honored to be part of your emotional wellness journey."
  ];
  
  return messages[Math.floor(Math.random() * messages.length)];
}

function generateMoodBasedResponse(userMessage, mood) {
  const detectedMood = detectMoodFromMessage(userMessage) || mood;
  
  const responses = {
    'happy': [
      "That sounds absolutely wonderful! Your joy is so uplifting. How does it feel to experience this happiness?",
      "I love hearing about the things that bring you joy. What else has been lighting up your life lately?",
      "Your positive energy is beautiful. How long have you been feeling this good about things?",
      "It's amazing when life feels this bright. What do you think is contributing most to these good feelings?"
    ],
    'sad': [
      "I hear the pain in your words, and I want you to know that your feelings are completely valid. What would help you most right now?",
      "Sometimes sadness needs to be felt fully before it can begin to heal. I'm here with you through this. How long have you been carrying this?",
      "Your sadness matters, and so do you. Would it help to talk about what's bringing up these feelings?",
      "Thank you for sharing something so personal. It takes courage to be vulnerable. How are you taking care of yourself through this?"
    ],
    'anxious': [
      "I can sense the worry in your words. Anxiety can feel so overwhelming, but you're handling it by reaching out. What's your biggest concern right now?",
      "Your anxiety makes sense given what you're going through. Let's slow down and take this one thought at a time. What feels most urgent?",
      "Anxiety often comes from caring deeply about outcomes. What's the underlying fear you're experiencing?",
      "You're not alone with these anxious thoughts. Sometimes talking through them helps. What scenario is your mind creating?"
    ],
    'angry': [
      "I can feel the strength of your emotions, and anger often signals that something important to you has been affected. What's at the core of this feeling?",
      "Your anger is telling us something important. Behind anger, there's often hurt or frustration. What's really going on?",
      "It's healthy to acknowledge anger rather than suppress it. What boundary has been crossed or what value has been challenged?",
      "Thank you for expressing this in a safe space. What would justice or resolution look like for you in this situation?"
    ],
    'tired': [
      "Exhaustion - both physical and emotional - is your body and mind asking for care. What's been demanding so much of your energy?",
      "Being tired often means we've been giving a lot of ourselves. What haven't you been able to rest from?",
      "Sometimes tired is a signal that we need to reassess our boundaries and priorities. What's been overwhelming you?",
      "Fatigue can be so isolating. You don't have to carry everything alone. What support do you need right now?"
    ],
    'depressed': [
      "Depression can make everything feel muted and distant. I want you to know that your feelings are valid and you matter. How are you getting through each day?",
      "Thank you for sharing despite how difficult it must be to put these feelings into words. What's been the hardest part about feeling this way?",
      "Depression tells us lies about our worth and future. You showed strength by reaching out today. What tiny thing has brought you any comfort recently?",
      "I see you trying, even when it feels impossible. That takes incredible courage. What's one small way I can support you right now?"
    ],
    'calm': [
      "There's something beautiful about finding moments of peace. What helps you access this sense of calm?",
      "Your tranquil energy is grounding. How do you cultivate and maintain this peaceful state?",
      "Calm can be such a gift, both to yourself and others around you. What thoughts or practices bring you to this place?"
    ],
    'excited': [
      "Your excitement is contagious! It's wonderful to witness such enthusiasm. What's creating this amazing energy for you?",
      "I love the vibrant energy you're bringing! Excitement can be such a powerful motivator. What possibilities are you seeing?",
      "There's something magical about pure excitement. How does it feel to be experiencing life so intensely right now?"
    ]
  };
  
  const moodResponses = responses[detectedMood] || [
    "I can hear the emotion in your words. Thank you for sharing so openly with me. What feels most important for you to express right now?",
    "Your feelings are completely valid. I'm here to listen and support you through whatever you're experiencing. What's in your heart?",
    "Every emotion tells us something important about our inner world. What is this feeling trying to tell you?",
    "I appreciate your honesty and vulnerability. How can I best support you in this moment?"
  ];
  
  return moodResponses[Math.floor(Math.random() * moodResponses.length)];
}

function detectMoodFromMessage(text) {
  const lowerText = text.toLowerCase();
  
  // Happy indicators
  if (lowerText.match(/\b(happy|joy|excited|amazing|wonderful|great|fantastic|thrilled|elated|cheerful|delighted)\b/)) {
    return 'happy';
  }
  
  // Sad indicators
  if (lowerText.match(/\b(sad|depressed|down|heartbroken|devastated|miserable|upset|crying|tears)\b/)) {
    return 'sad';
  }
  
  // Anxious indicators
  if (lowerText.match(/\b(anxious|worried|nervous|stressed|panic|overwhelmed|scared|frightened|tense)\b/)) {
    return 'anxious';
  }
  
  // Angry indicators
  if (lowerText.match(/\b(angry|mad|furious|irritated|frustrated|annoyed|rage|pissed|livid)\b/)) {
    return 'angry';
  }
  
  // Tired indicators
  if (lowerText.match(/\b(tired|exhausted|drained|weary|fatigued|worn out|depleted|spent)\b/)) {
    return 'tired';
  }
  
  // Depressed indicators
  if (lowerText.match(/\b(depressed|hopeless|empty|numb|worthless|suicidal|meaningless|dark)\b/)) {
    return 'depressed';
  }
  
  // Calm indicators
  if (lowerText.match(/\b(calm|peaceful|serene|relaxed|tranquil|centered|balanced|zen)\b/)) {
    return 'calm';
  }
  
  return null; // Let the original mood stand
}

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`🌟 MoodSync Server running on port ${PORT}`);
  console.log(`🔗 Server URL: http://localhost:${PORT}`);
  console.log('📡 Available endpoints:');
  console.log('   - GET  /health');
  console.log('   - POST /register');
  console.log('   - POST /login');
  console.log('   - GET  /users (debug)');
  console.log('🤖 AI Features: Mood Detection, Emotional Support, Real-time Chat');
  console.log('🚀 Ready to help users on their emotional wellness journey!');
});