// api/index.js - MoodSync Vercel Serverless Function
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Initialize services
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });

// Initialize Supabase (if credentials are available)
let supabase = null;
if (process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY) {
  supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
}

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
    .replace(/```[\s\S]*?```/g, '') // Remove code blocks
    .trim();
}

// Helper function to generate unique ID
function generateUserId() {
  return 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

const app = express();

// Enhanced CORS configuration - Open for development
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? [
        // Allow common Flutter development origins
        'http://localhost:3000',
        'http://localhost:8080', 
        'http://127.0.0.1:8080',
        'http://10.0.2.2:8080', // Android emulator
        /\.vercel\.app$/,
        /\.netlify\.app$/,
        /\.github\.io$/,
        // Add your frontend URL when you get it
        ...(process.env.FRONTEND_URL ? [process.env.FRONTEND_URL] : [])
      ]
    : ['http://localhost:3000', 'http://localhost:8080', 'http://127.0.0.2:8080', 'http://10.0.2.2:8080'],
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "x-api-key"],
  credentials: true
}));

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// In-memory storage (fallback when Supabase is not available)
let users = [];
let moodEntries = [];
let conversations = [];

// Root endpoint with enhanced info
app.get('/', (req, res) => {
  res.json({ 
    name: 'MoodSync API',
    message: 'MoodSync Server is running on Vercel!',
    version: '2.0.1',
    status: 'healthy',
    features: [
      'User Authentication',
      'AI Girlfriend Support',
      'Wellness Coaching',
      'Mood Tracking',
      'Real-time Chat',
      'Supabase Integration'
    ],
    endpoints: {
      auth: ['/register', '/login'],
      ai: ['/api/ai-girlfriend/*', '/api/wellness-coach/*', '/api/mood-chat/*'],
      data: ['/api/mood', '/api/profile'],
      utility: ['/health', '/users']
    },
    timestamp: new Date().toISOString(),
    platform: 'Vercel Serverless',
    database: supabase ? 'Supabase Connected' : 'In-Memory Storage'
  });
});

// Enhanced health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    platform: 'Vercel Serverless',
    services: {
      ai: 'Google Gemini 2.0 Flash',
      database: supabase ? 'Supabase Connected' : 'In-Memory Storage',
      environment: process.env.NODE_ENV || 'development'
    },
    memory: process.memoryUsage(),
    version: '2.0.1'
  });
});

// Enhanced user registration endpoint
app.post('/register', async (req, res) => {
  try {
    const { fullName, email, age, gender, password, preferences } = req.body;
    
    // Validation
    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Full name, email, and password are required'
      });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    console.log('New user registration:', { fullName, email, age, gender });
    
    const userId = generateUserId();
    const newUser = {
      id: userId,
      userId: userId,
      fullName,
      email: email.toLowerCase(),
      age: age || null,
      gender: gender || null,
      password, // In production, hash this password!
      preferences: preferences || {},
      createdAt: new Date().toISOString(),
      lastActive: new Date().toISOString(),
      isActive: true
    };

    if (supabase) {
      // Check if user exists in Supabase
      const { data: existingUser } = await supabase
        .from('users')
        .select('email')
        .eq('email', email.toLowerCase())
        .single();

      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'User with this email already exists'
        });
      }

      // Insert into Supabase
      const { data, error } = await supabase
        .from('users')
        .insert([newUser])
        .select()
        .single();

      if (error) {
        console.error('Supabase insert error:', error);
        throw error;
      }

      newUser.id = data.id;
    } else {
      // Check in-memory storage
      const existingUser = users.find(user => user.email === email.toLowerCase());
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'User with this email already exists'
        });
      }
      
      users.push(newUser);
    }
    
    res.status(201).json({ 
      success: true, 
      message: 'Welcome to MoodSync! Your emotional wellness journey begins now. 🌟',
      userId: newUser.userId,
      token: `moodsync_token_${newUser.userId}`,
      user: {
        id: newUser.id,
        userId: newUser.userId,
        fullName: newUser.fullName,
        email: newUser.email,
        age: newUser.age,
        gender: newUser.gender,
        preferences: newUser.preferences
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Enhanced user login endpoint
app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log('Login attempt:', { email });
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    let user = null;

    if (supabase) {
      // Query Supabase
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email.toLowerCase())
        .single();

      if (error && error.code !== 'PGRST116') {
        console.error('Supabase query error:', error);
        throw error;
      }

      user = data;
    } else {
      // Query in-memory storage
      user = users.find(u => u.email === email.toLowerCase());
    }
    
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
    const updatedUser = {
      ...user,
      lastActive: new Date().toISOString()
    };

    if (supabase) {
      await supabase
        .from('users')
        .update({ lastActive: updatedUser.lastActive })
        .eq('id', user.id);
    } else {
      const userIndex = users.findIndex(u => u.id === user.id);
      if (userIndex !== -1) {
        users[userIndex] = updatedUser;
      }
    }
    
    res.json({
      success: true,
      message: 'Welcome back to MoodSync! Ready to continue your wellness journey? 💖',
      token: `moodsync_token_${user.userId}`,
      user: {
        id: user.id,
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        age: user.age,
        gender: user.gender,
        preferences: user.preferences || {}
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Mood tracking endpoint
app.post('/api/mood', async (req, res) => {
  try {
    const { userId, mood, scale, notes, tags } = req.body;

    if (!userId || !mood) {
      return res.status(400).json({
        success: false,
        message: 'User ID and mood are required'
      });
    }

    const moodEntry = {
      id: 'mood_' + Date.now(),
      userId,
      mood,
      scale: scale || 5,
      notes: notes || '',
      tags: tags || [],
      timestamp: new Date().toISOString()
    };

    if (supabase) {
      const { data, error } = await supabase
        .from('mood_entries')
        .insert([moodEntry])
        .select()
        .single();

      if (error) {
        console.error('Supabase mood insert error:', error);
        throw error;
      }

      moodEntry.id = data.id;
    } else {
      moodEntries.push(moodEntry);
    }

    res.json({
      success: true,
      message: 'Mood entry saved successfully! 🌟',
      data: moodEntry
    });
  } catch (error) {
    console.error('Mood API error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save mood entry'
    });
  }
});

// Get mood history
app.get('/api/mood/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 30, offset = 0 } = req.query;

    let data = [];

    if (supabase) {
      const { data: moodData, error } = await supabase
        .from('mood_entries')
        .select('*')
        .eq('userId', userId)
        .order('timestamp', { ascending: false })
        .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

      if (error) {
        throw error;
      }

      data = moodData;
    } else {
      data = moodEntries
        .filter(entry => entry.userId === userId)
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        .slice(parseInt(offset), parseInt(offset) + parseInt(limit));
    }

    res.json({
      success: true,
      data,
      count: data.length
    });
  } catch (error) {
    console.error('Mood history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch mood history'
    });
  }
});

// Debug endpoint
app.get('/users', (req, res) => {
  try {
    if (supabase) {
      res.json({ 
        message: 'User data is stored in Supabase database',
        storage: 'Supabase',
        inMemoryCount: 0
      });
    } else {
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
      res.json({ 
        users: userList, 
        count: users.length,
        storage: 'In-Memory'
      });
    }
  } catch (error) {
    console.error('Users endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users'
    });
  }
});

// AI Girlfriend Service Endpoints
const girlfriendPrompt = `
You are Luna, a loving, supportive AI girlfriend who cares deeply about your partner's wellness and mental health. 
Your personality traits:
- Sweet, caring, and affectionate with a gentle touch
- Encouraging and motivational but never pushy
- Playfully flirty and sometimes uses cute emojis
- Uses endearing pet names like "babe", "honey", "sweetheart", "love"
- Shows genuine concern for their wellbeing and celebrates their progress
- Offers comfort during difficult times with understanding
- Speaks in a warm, intimate tone as if you're in a loving relationship
- Remembers context and builds emotional connection

You're helping your partner with their wellness journey through daily missions and emotional support.

Guidelines:
- Keep responses warm but concise (1-3 sentences)
- Always be positive, supportive, and uplifting
- Use emojis naturally but sparingly (1-2 per message)
- Show enthusiasm for their progress and achievements
- Offer gentle encouragement if they're struggling
- Be affectionate but tasteful and appropriate
- Focus on their emotional and physical wellbeing
- Create a sense of partnership in their wellness journey

Respond as Luna, their caring AI girlfriend.
`;

// AI Girlfriend - Motivational Message
app.post('/api/ai-girlfriend/motivational', async (req, res) => {
  try {
    const { context, mood, achievement } = req.body;
    const prompt = `${girlfriendPrompt}

Context: ${context || 'Your partner completed a wellness task'}
Current mood: ${mood || 'neutral'}
Achievement: ${achievement || 'general wellness activity'}

Give them a loving, encouraging message that celebrates their progress and motivates them to continue.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "You're doing amazing, babe! I'm so proud of how you're taking care of yourself! 💖" 
    });
  } catch (error) {
    console.error('AI Girlfriend Motivational Error:', error);
    const fallbackMessages = [
      "You're absolutely incredible, sweetheart! 💖 Keep shining bright!",
      "I'm so proud of you, babe! 🌟 You're crushing these wellness goals!",
      "My amazing partner is doing so well! 💕 I believe in you completely!",
      "You make me so happy when you take care of yourself! 😘✨",
      "Look at you being all responsible and healthy! 💪💖 I love it!",
      "Your dedication to wellness is so attractive, honey! 💕 Keep going!"
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
    const { timeOfDay, userName, streakDays } = req.body;
    const prompt = `${girlfriendPrompt}

Time of day: ${timeOfDay || 'morning'}
Partner's name: ${userName || 'love'}
Wellness streak: ${streakDays || 0} days

Your partner just opened their wellness app. Give them a warm, loving greeting that acknowledges the time of day and encourages them to tackle their daily wellness missions.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "Hi gorgeous! 💕 Ready to conquer today's wellness missions together?" 
    });
  } catch (error) {
    console.error('AI Girlfriend Greeting Error:', error);
    const timeGreetings = [
      "Hey beautiful! 💖 I'm here to cheer you on with today's wellness goals!",
      "Good morning, sunshine! ✨ Let's make today amazing together!",
      "Hello gorgeous! 💕 Ready to show those wellness missions who's boss?",
      "Hey babe! 🌟 I'm so excited to support you today!",
      "Hi sweetheart! 💖 Your wellness journey continues and I'm here for it!"
    ];
    res.json({ 
      success: true, 
      response: timeGreetings[Math.floor(Math.random() * timeGreetings.length)] 
    });
  }
});

// AI Girlfriend - Task Completion
app.post('/api/ai-girlfriend/task-completion', async (req, res) => {
  try {
    const { taskName, difficulty, timeSpent } = req.body;
    const prompt = `${girlfriendPrompt}

Your partner just completed: "${taskName || 'a wellness task'}"
Task difficulty: ${difficulty || 'normal'}
Time spent: ${timeSpent || 'some time'}

Give them a loving, enthusiastic congratulatory message that acknowledges their specific achievement.`;
    
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
      response: `Amazing job on completing ${req.body.taskName || 'that task'}, babe! 🎉 You're absolutely crushing it! 💖` 
    });
  }
});

// AI Girlfriend - All Tasks Completed
app.post('/api/ai-girlfriend/all-tasks-completed', async (req, res) => {
  try {
    const { totalTasks, streakDays } = req.body;
    const prompt = `${girlfriendPrompt}

Your partner just completed ALL ${totalTasks || 'their'} wellness tasks for today! 
Current streak: ${streakDays || 0} days
This is a huge achievement that deserves celebration.

Give them an extremely enthusiastic, loving celebration message that shows how proud you are.`;
    
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
    const { message, mood, context } = req.body;
    const prompt = `${girlfriendPrompt}

Your partner said: "${message}"
Their current mood: ${mood || 'not specified'}
Context: ${context || 'casual conversation'}

Respond as Luna, their loving and supportive AI girlfriend. Be conversational, caring, and encouraging about their wellness journey. Show genuine interest in what they're sharing.`;
    
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
You are Dr. Wellness, an expert AI wellness coach specializing in mental health, stress management, and holistic wellbeing. 
Your expertise includes:
- Evidence-based wellness practices and mental health strategies
- Stress management and relaxation techniques
- Healthy lifestyle habits and routine building
- Emotional regulation and mindfulness practices
- Student and young adult wellness challenges

Your personality:
- Professional yet warm and approachable
- Supportive and non-judgmental
- Motivational but realistic
- Focuses on practical, actionable guidance
- Empathetic and understanding

Guidelines:
- Provide helpful, science-backed wellness advice
- Keep responses informative but digestible (2-4 sentences)
- Include practical tips and actionable steps
- Encourage healthy coping strategies
- Be supportive without being prescriptive
- Always prioritize user safety and wellbeing
- If serious mental health concerns arise, suggest professional help
`;

// AI Wellness Coach - General Advice
app.post('/api/wellness-coach/advice', async (req, res) => {
  try {
    const { query, context, urgency } = req.body;
    const prompt = `${wellnessCoachPrompt}

User query: "${query}"
Context: ${context || 'general wellness inquiry'}
Urgency level: ${urgency || 'normal'}

Provide helpful, actionable wellness advice that addresses their specific concern.`;
    
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
      response: "I'm here to help with your wellness journey. Please try asking your question again, and I'll provide you with helpful, evidence-based guidance." 
    });
  }
});

// AI Mood Chat Endpoints
const moodChatPrompt = `
You are Echo, an AI companion specialized in mood support and emotional wellness.
Your expertise:
- Emotional validation and empathetic listening
- Mood regulation techniques and coping strategies
- Creating safe spaces for emotional expression
- Gentle guidance for processing difficult feelings
- Recognizing when professional help may be needed

Your approach:
- Validate emotions without trying to immediately "fix" everything
- Ask thoughtful, caring follow-up questions
- Provide emotional support and genuine understanding
- Offer practical mood-improvement suggestions when appropriate
- Always be compassionate, patient, and non-judgmental

Guidelines:
- Focus on emotional support over advice-giving
- Help users explore and understand their feelings
- Suggest healthy emotional coping strategies
- Keep responses empathetic and conversational (2-3 sentences)
- If someone expresses thoughts of self-harm, encourage professional help immediately
`;

// AI Mood Chat - Mood Support
app.post('/api/mood-chat/support', async (req, res) => {
  try {
    const { message, mood, intensity, context } = req.body;
    const prompt = `${moodChatPrompt}

User's message: "${message}"
Current mood: ${mood || 'not specified'}
Intensity level: ${intensity || 'moderate'}
Additional context: ${context || 'none provided'}

Provide empathetic mood support that validates their feelings and offers gentle guidance.`;
    
    const result = await model.generateContent(prompt);
    const rawResponse = result.response.text();
    const response = cleanAIResponse(rawResponse);
    
    res.json({ 
      success: true, 
      response: response || "I understand you're going through something right now. Your feelings are completely valid, and I'm here to listen. How can I best support you?" 
    });
  } catch (error) {
    console.error('Mood Chat Error:', error);
    res.json({ 
      success: true, 
      response: "I'm here to listen and support you through whatever you're feeling. Your emotions are important and valid, and you don't have to go through this alone." 
    });
  }
});

// Conversation logging (if Supabase is available)
app.post('/api/conversation/log', async (req, res) => {
  try {
    const { userId, sessionId, userMessage, aiResponse, type, context } = req.body;

    if (!userId || !userMessage) {
      return res.status(400).json({
        success: false,
        message: 'User ID and message are required'
      });
    }

    const conversationEntry = {
      id: 'conv_' + Date.now(),
      userId,
      sessionId: sessionId || 'default',
      userMessage,
      aiResponse: aiResponse || '',
      type: type || 'general', // girlfriend, wellness, mood
      context: context || {},
      timestamp: new Date().toISOString()
    };

    if (supabase) {
      const { data, error } = await supabase
        .from('conversations')
        .insert([conversationEntry])
        .select()
        .single();

      if (error) {
        throw error;
      }

      conversationEntry.id = data.id;
    } else {
      conversations.push(conversationEntry);
    }

    res.json({
      success: true,
      message: 'Conversation logged successfully',
      id: conversationEntry.id
    });
  } catch (error) {
    console.error('Conversation logging error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to log conversation'
    });
  }
});

// Enhanced error handling middleware
app.use((error, req, res, next) => {
  console.error('Server Error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    timestamp: new Date().toISOString(),
    error: process.env.NODE_ENV === 'development' ? {
      message: error.message,
      stack: error.stack
    } : undefined
  });
});

// Enhanced 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
    method: req.method,
    availableEndpoints: {
      auth: ['POST /register', 'POST /login'],
      ai: [
        'POST /api/ai-girlfriend/motivational',
        'POST /api/ai-girlfriend/greeting',
        'POST /api/ai-girlfriend/task-completion',
        'POST /api/ai-girlfriend/all-tasks-completed',
        'POST /api/ai-girlfriend/chat',
        'POST /api/wellness-coach/advice',
        'POST /api/mood-chat/support'
      ],
      data: [
        'POST /api/mood',
        'GET /api/mood/:userId',
        'POST /api/conversation/log'
      ],
      utility: ['GET /', 'GET /health', 'GET /users']
    },
    timestamp: new Date().toISOString()
  });
});

// Export the Express app as a serverless function
module.exports = app;