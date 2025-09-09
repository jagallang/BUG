require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Initialize Express app
const app = express();

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  storageBucket: 'bugcash-platform.appspot.com'
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://bugcash.app', 'https://app.bugcash.app'] 
    : ['http://localhost:3000', 'http://localhost:57489'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '300mb' }));
app.use(express.urlencoded({ extended: true, limit: '300mb' }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/apps', require('./routes/apps'));
app.use('/api/missions', require('./routes/missions'));
app.use('/api/upload', require('./routes/upload'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/analytics', require('./routes/analytics'));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'BugCash API Server'
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

const PORT = process.env.PORT || 3000;

if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => {
    console.log(`🚀 BugCash Server running on port ${PORT}`);
  });
}

// Export for Firebase Functions
exports.api = functions.https.onRequest(app);