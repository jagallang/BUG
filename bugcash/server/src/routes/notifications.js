const express = require('express');

const router = express.Router();

// Mock notifications data
const mockNotifications = [
  {
    id: 'notif-1',
    recipientId: 'mock-user-123',
    type: 'mission_completed',
    title: '미션 완료',
    message: 'UI/UX 버그 탐지 미션을 성공적으로 완료했습니다!',
    data: {
      missionId: 'mission-2',
      reward: 8000
    },
    createdAt: '2024-09-08T10:00:00Z',
    read: false
  },
  {
    id: 'notif-2',
    recipientId: 'mock-user-123',
    type: 'reward_received',
    title: '리워드 지급',
    message: '8,000 포인트가 지급되었습니다.',
    data: {
      amount: 8000,
      missionId: 'mission-2'
    },
    createdAt: '2024-09-08T10:05:00Z',
    read: false
  }
];

// Get user notifications
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 50, unreadOnly = 'false' } = req.query;
    
    let userNotifications = mockNotifications.filter(notif => notif.recipientId === userId);
    
    if (unreadOnly === 'true') {
      userNotifications = userNotifications.filter(notif => !notif.read);
    }
    
    userNotifications = userNotifications
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, parseInt(limit));
    
    const unreadCount = mockNotifications.filter(notif => 
      notif.recipientId === userId && !notif.read
    ).length;
    
    res.json({
      success: true,
      notifications: userNotifications,
      unreadCount
    });
    
  } catch (error) {
    console.error('Notifications fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Mark notification as read
router.patch('/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    const notification = mockNotifications.find(n => n.id === notificationId);
    
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    notification.read = true;
    
    res.json({
      success: true,
      message: 'Notification marked as read'
    });
    
  } catch (error) {
    console.error('Notification update error:', error);
    res.status(500).json({ error: 'Failed to update notification' });
  }
});

// Mark all notifications as read
router.patch('/user/:userId/read-all', async (req, res) => {
  try {
    const { userId } = req.params;
    
    mockNotifications
      .filter(notif => notif.recipientId === userId)
      .forEach(notif => notif.read = true);
    
    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
    
  } catch (error) {
    console.error('Notifications update error:', error);
    res.status(500).json({ error: 'Failed to update notifications' });
  }
});

// Send notification (internal use)
router.post('/', async (req, res) => {
  try {
    const { recipientId, type, title, message, data } = req.body;
    
    const notification = {
      id: `notif-${Date.now()}`,
      recipientId,
      type,
      title,
      message,
      data: data || {},
      createdAt: new Date().toISOString(),
      read: false
    };
    
    mockNotifications.push(notification);
    
    res.status(201).json({
      success: true,
      notification,
      message: 'Notification sent successfully'
    });
    
  } catch (error) {
    console.error('Notification send error:', error);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

module.exports = router;