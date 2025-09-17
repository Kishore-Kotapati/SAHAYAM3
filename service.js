// create-service.js - Windows Service Setup
const Service = require('node-windows').Service;
const path = require('path');

// Create a new service object
const svc = new Service({
  name: 'MoodSync Server',
  description: 'MoodSync AI-powered emotional wellness chat platform server',
  script: path.join(__dirname, 'server.js'),
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ],
  env: [
    {
      name: "NODE_ENV",
      value: "production"
    },
    {
      name: "PORT", 
      value: "3000"
    },
    {
      name: "GEMINI_API_KEY",
      value: process.env.GEMINI_API_KEY || "AIzaSyBrtqlw5sysR_-htsDl03RLZuGEXPnIAnk"
    }
  ]
});

// Listen for the "install" event, which indicates the process is available as a service.
svc.on('install', function() {
  console.log('✅ MoodSync Server service installed successfully!');
  console.log('🚀 Starting the service...');
  svc.start();
});

svc.on('start', function() {
  console.log('🌟 MoodSync Server service started successfully!');
  console.log('🔗 Server should be running on http://localhost:3000');
  console.log('📊 You can check Windows Services to manage it');
});

svc.on('alreadyinstalled', function() {
  console.log('⚠️  MoodSync Server service is already installed.');
  console.log('🔄 You can uninstall it first with: node uninstall-service.js');
});

console.log('🔧 Installing MoodSync Server as Windows Service...');
svc.install();