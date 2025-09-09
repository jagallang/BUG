const express = require('express');
const admin = require('firebase-admin');
const { body, validationResult } = require('express-validator');

const router = express.Router();

// Mock authentication for development
router.post('/register', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('displayName').notEmpty().withMessage('Display name is required'),
  body('userType').isIn(['tester', 'provider']).withMessage('User type must be tester or provider'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, displayName, userType } = req.body;

    // In development, just return mock response
    const mockUser = {
      uid: `mock-${Date.now()}`,
      email,
      displayName,
      userType,
      createdAt: new Date().toISOString()
    };

    res.status(201).json({
      success: true,
      user: mockUser,
      message: 'User registered successfully (mock)'
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // Mock login for development
    const mockUser = {
      uid: 'mock-user-123',
      email,
      displayName: 'Demo User',
      userType: 'tester',
      points: 75000,
      level: 3,
      completedMissions: 12
    };

    res.json({
      success: true,
      user: mockUser,
      token: 'mock-jwt-token',
      message: 'Login successful (mock)'
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

router.post('/logout', (req, res) => {
  res.json({ success: true, message: 'Logout successful' });
});

router.get('/profile', (req, res) => {
  // Mock profile data
  const mockProfile = {
    uid: 'mock-user-123',
    email: 'demo@bugcash.com',
    displayName: 'Demo User',
    userType: 'tester',
    points: 75000,
    level: 3,
    completedMissions: 12,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: new Date().toISOString()
  };

  res.json({
    success: true,
    user: mockProfile
  });
});

module.exports = router;