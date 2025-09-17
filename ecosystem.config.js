module.exports = {
  apps: [{
    name: 'moodsync-server',
    script: './server.js',
    
    // Basic Configuration
    instances: 1,
    exec_mode: 'fork',
    
    // Auto-restart settings
    autorestart: true,
    watch: false, // Set to true for development
    max_memory_restart: '1G',
    
    // Environment variables
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      GEMINI_API_KEY: process.env.GEMINI_API_KEY || 'AIzaSyBrtqlw5sysR_-htsDl03RLZuGEXPnIAnk'
    },
    
    // Development environment
    env_development: {
      NODE_ENV: 'development',
      PORT: 3000,
      watch: true,
      ignore_watch: ['node_modules', 'logs']
    },
    
    // Logging
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Advanced PM2 features
    min_uptime: '10s',
    max_restarts: 10,
    
    // Cron restart (optional - restart every day at 2 AM)
    // cron_restart: '0 2 * * *',
    
    // Merge logs
    merge_logs: true,
    
    // Source map support
    source_map_support: true
  }]
};