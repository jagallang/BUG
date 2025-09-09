const express = require('express');
const { body, validationResult } = require('express-validator');

const router = express.Router();

// Mock missions data
const mockMissions = [
  {
    id: 'mission-1',
    title: '앱 설치 및 첫 실행 테스트',
    description: 'BugCash 테스트 앱을 설치하고 첫 실행 시 발생하는 이슈를 찾아주세요.',
    reward: 5000,
    difficulty: 'easy',
    category: 'functional',
    status: 'active',
    participantCount: 15,
    maxParticipants: 20,
    providerId: 'provider-1',
    appId: 'app-1',
    createdAt: '2024-09-01T00:00:00Z',
    updatedAt: '2024-09-08T12:00:00Z'
  },
  {
    id: 'mission-2',
    title: 'UI/UX 버그 탐지',
    description: '앱의 사용자 인터페이스에서 발생할 수 있는 디자인 버그나 사용성 문제를 찾아주세요.',
    reward: 8000,
    difficulty: 'medium',
    category: 'ui_ux',
    status: 'active',
    participantCount: 8,
    maxParticipants: 15,
    providerId: 'provider-2',
    appId: 'app-2',
    createdAt: '2024-09-02T00:00:00Z',
    updatedAt: '2024-09-08T14:00:00Z'
  }
];

// Get all missions
router.get('/', async (req, res) => {
  try {
    const { category, difficulty, status = 'active', limit = 50 } = req.query;
    
    let filteredMissions = mockMissions.filter(mission => mission.status === status);
    
    if (category && category !== 'all') {
      filteredMissions = filteredMissions.filter(mission => mission.category === category);
    }
    
    if (difficulty && difficulty !== 'all') {
      filteredMissions = filteredMissions.filter(mission => mission.difficulty === difficulty);
    }
    
    filteredMissions = filteredMissions.slice(0, parseInt(limit));
    
    res.json({
      success: true,
      missions: filteredMissions,
      total: filteredMissions.length
    });
    
  } catch (error) {
    console.error('Missions fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch missions' });
  }
});

// Get mission by ID
router.get('/:missionId', async (req, res) => {
  try {
    const { missionId } = req.params;
    
    const mission = mockMissions.find(m => m.id === missionId);
    
    if (!mission) {
      return res.status(404).json({ error: 'Mission not found' });
    }
    
    res.json({
      success: true,
      mission
    });
    
  } catch (error) {
    console.error('Mission detail fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch mission details' });
  }
});

// Create new mission (provider only)
router.post('/', [
  body('title').isLength({ min: 5, max: 100 }).withMessage('Title must be 5-100 characters'),
  body('description').isLength({ min: 20, max: 1000 }).withMessage('Description must be 20-1000 characters'),
  body('reward').isInt({ min: 1000, max: 100000 }).withMessage('Reward must be between 1000-100000'),
  body('difficulty').isIn(['easy', 'medium', 'hard']).withMessage('Invalid difficulty'),
  body('category').isIn(['functional', 'ui_ux', 'performance', 'security']).withMessage('Invalid category'),
  body('maxParticipants').isInt({ min: 1, max: 100 }).withMessage('Max participants must be 1-100'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const missionData = {
      id: `mission-${Date.now()}`,
      ...req.body,
      status: 'active',
      participantCount: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // In real implementation, save to database
    mockMissions.push(missionData);

    res.status(201).json({
      success: true,
      mission: missionData,
      message: 'Mission created successfully'
    });

  } catch (error) {
    console.error('Mission creation error:', error);
    res.status(500).json({ error: 'Failed to create mission' });
  }
});

// Join mission (tester)
router.post('/:missionId/join', async (req, res) => {
  try {
    const { missionId } = req.params;
    const { testerId } = req.body;

    if (!testerId) {
      return res.status(400).json({ error: 'Tester ID is required' });
    }

    const mission = mockMissions.find(m => m.id === missionId);
    
    if (!mission) {
      return res.status(404).json({ error: 'Mission not found' });
    }

    if (mission.participantCount >= mission.maxParticipants) {
      return res.status(400).json({ error: 'Mission is full' });
    }

    // In real implementation, check if already joined and update database
    mission.participantCount += 1;

    res.json({
      success: true,
      message: 'Successfully joined mission'
    });

  } catch (error) {
    console.error('Mission join error:', error);
    res.status(500).json({ error: 'Failed to join mission' });
  }
});

module.exports = router;