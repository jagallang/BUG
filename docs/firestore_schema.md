# BugCash Firestore Database Schema

## Collection Structure

### 1. users
사용자 정보 (테스터와 제공자 모두)
```
users/{userId}
├── email: string
├── displayName: string
├── photoURL: string (optional)
├── userType: 'tester' | 'provider'
├── phoneNumber: string (optional)
├── country: string
├── timezone: string
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── isActive: boolean
├── lastLoginAt: Timestamp
└── profile: Map
    ├── bio: string (optional)
    ├── skills: array<string>
    ├── languages: array<string>
    └── preferences: Map
```

### 2. providers
앱 제공자 정보 (users의 확장)
```
providers/{userId}
├── companyName: string
├── companySize: 'startup' | 'small' | 'medium' | 'large' | 'enterprise'
├── industry: string
├── website: string (optional)
├── address: Map
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   ├── zipCode: string
│   └── country: string
├── businessEmail: string
├── phoneNumber: string
├── taxId: string (optional)
├── bankAccount: Map (optional)
│   ├── accountHolder: string
│   ├── bankName: string
│   ├── accountNumber: string (encrypted)
│   └── routingNumber: string (encrypted)
├── subscription: Map
│   ├── plan: 'basic' | 'premium' | 'enterprise'
│   ├── startDate: Timestamp
│   ├── endDate: Timestamp
│   └── isActive: boolean
├── stats: Map
│   ├── totalMissions: number
│   ├── activeMissions: number
│   ├── completedMissions: number
│   ├── totalSpent: number
│   ├── averageRating: number
│   └── totalTesters: number
└── verificationStatus: 'pending' | 'verified' | 'rejected'
```

### 3. testers
테스터 정보 (users의 확장)
```
testers/{userId}
├── experience: Map
│   ├── level: 'beginner' | 'intermediate' | 'advanced' | 'expert'
│   ├── yearsOfExperience: number
│   ├── totalMissionsCompleted: number
│   └── specializations: array<string>
├── devices: array<Map>
│   ├── id: string (auto-generated)
│   ├── deviceType: 'phone' | 'tablet' | 'smartwatch' | 'tv' | 'web'
│   ├── platform: 'android' | 'ios' | 'windows' | 'macos' | 'linux' | 'web'
│   ├── brand: string
│   ├── model: string
│   ├── osVersion: string
│   ├── screenSize: string
│   ├── resolution: string
│   ├── isActive: boolean
│   └── addedAt: Timestamp
├── bankingInfo: Map (optional)
│   ├── accountHolder: string
│   ├── bankName: string
│   ├── accountNumber: string (encrypted)
│   ├── routingNumber: string (encrypted)
│   └── paypalEmail: string (optional)
├── earnings: Map
│   ├── totalEarned: number
│   ├── availableBalance: number
│   ├── pendingBalance: number
│   └── lastPayoutAt: Timestamp (optional)
├── rating: Map
│   ├── average: number
│   ├── totalReviews: number
│   └── breakdown: Map
│       ├── communication: number
│       ├── quality: number
│       ├── timeliness: number
│       └── thoroughness: number
├── availability: Map
│   ├── status: 'available' | 'busy' | 'inactive'
│   ├── preferredHours: Map
│   │   ├── start: string (HH:MM)
│   │   └── end: string (HH:MM)
│   └── maxConcurrentMissions: number
└── verificationStatus: 'pending' | 'verified' | 'rejected'
```

### 4. missions
미션 정보
```
missions/{missionId}
├── providerId: string (reference to users/{userId})
├── appId: string (reference to apps/{appId})
├── title: string
├── description: string
├── type: 'functional' | 'ui_ux' | 'performance' | 'security' | 'compatibility' | 'accessibility' | 'localization'
├── priority: 'low' | 'medium' | 'high' | 'critical'
├── complexity: 'simple' | 'moderate' | 'complex'
├── difficulty: 'easy' | 'medium' | 'hard' | 'expert'
├── status: 'draft' | 'active' | 'paused' | 'completed' | 'cancelled'
├── requirements: Map
│   ├── platforms: array<string>
│   ├── devices: array<string>
│   ├── osVersions: array<string>
│   ├── languages: array<string>
│   ├── experience: string
│   ├── minRating: number
│   └── specialSkills: array<string>
├── participation: Map
│   ├── maxTesters: number
│   ├── currentTesters: number
│   ├── autoAssign: boolean
│   └── inviteOnly: boolean
├── timeline: Map
│   ├── startDate: Timestamp
│   ├── endDate: Timestamp
│   ├── testingDuration: number (days)
│   └── reportingDuration: number (days)
├── rewards: Map
│   ├── baseReward: number
│   ├── bonusReward: number (optional)
│   ├── currency: string
│   ├── paymentMethod: 'points' | 'cash'
│   └── bonusConditions: array<string>
├── attachments: array<Map>
│   ├── id: string
│   ├── name: string
│   ├── url: string
│   ├── type: 'apk' | 'ipa' | 'document' | 'image' | 'video'
│   ├── size: number
│   └── uploadedAt: Timestamp
├── testingGuidelines: Map
│   ├── instructions: string
│   ├── testCases: array<Map>
│   │   ├── id: string
│   │   ├── title: string
│   │   ├── steps: array<string>
│   │   ├── expectedResult: string
│   │   └── priority: 'low' | 'medium' | 'high'
│   ├── focusAreas: array<string>
│   └── excludedAreas: array<string>
├── analytics: Map
│   ├── views: number
│   ├── applications: number
│   ├── acceptanceRate: number
│   ├── avgCompletionTime: number
│   └── satisfactionScore: number
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── publishedAt: Timestamp (optional)
└── completedAt: Timestamp (optional)
```

### 5. apps
앱 정보
```
apps/{appId}
├── providerId: string (reference to users/{userId})
├── name: string
├── description: string
├── category: string
├── platforms: array<string>
├── version: string
├── packageName: string (Android) / bundleId: string (iOS)
├── icon: string (URL)
├── screenshots: array<string> (URLs)
├── downloadUrl: string (optional)
├── playStoreUrl: string (optional)
├── appStoreUrl: string (optional)
├── website: string (optional)
├── supportEmail: string
├── privacyPolicyUrl: string
├── termsOfServiceUrl: string
├── targetAudience: Map
│   ├── ageRange: string
│   ├── demographics: array<string>
│   └── regions: array<string>
├── technicalInfo: Map
│   ├── minOsVersion: Map
│   │   ├── android: string
│   │   └── ios: string
│   ├── permissions: array<string>
│   ├── apiIntegrations: array<string>
│   └── specialRequirements: array<string>
├── stats: Map
│   ├── totalDownloads: number
│   ├── activeUsers: number
│   ├── totalMissions: number
│   ├── activeMissions: number
│   └── averageRating: number
├── isActive: boolean
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### 6. mission_applications
미션 지원 정보
```
mission_applications/{applicationId}
├── missionId: string (reference to missions/{missionId})
├── testerId: string (reference to users/{userId})
├── providerId: string (reference to users/{userId})
├── status: 'pending' | 'accepted' | 'rejected' | 'in_progress' | 'completed' | 'cancelled'
├── applicationMessage: string (optional)
├── matchingScore: number (0-100)
├── selectionReason: string (optional)
├── assignment: Map (if accepted)
│   ├── assignedAt: Timestamp
│   ├── startedAt: Timestamp (optional)
│   ├── expectedCompletionDate: Timestamp
│   └── actualCompletionDate: Timestamp (optional)
├── progress: Map (if in_progress)
│   ├── percentage: number (0-100)
│   ├── lastUpdate: Timestamp
│   ├── milestonesCompleted: array<string>
│   └── estimatedCompletionDate: Timestamp
├── earnings: Map (if completed)
│   ├── baseAmount: number
│   ├── bonusAmount: number
│   ├── totalAmount: number
│   ├── currency: string
│   └── paidAt: Timestamp (optional)
├── feedback: Map (optional)
│   ├── testerRating: number (1-5)
│   ├── providerRating: number (1-5)
│   ├── testerFeedback: string
│   ├── providerFeedback: string
│   └── platformFeedback: string
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### 7. bug_reports
버그 리포트 정보
```
bug_reports/{reportId}
├── missionId: string (reference to missions/{missionId})
├── testerId: string (reference to users/{userId})
├── providerId: string (reference to users/{userId})
├── appId: string (reference to apps/{appId})
├── title: string
├── description: string
├── severity: 'low' | 'medium' | 'high' | 'critical'
├── priority: 'low' | 'medium' | 'high' | 'urgent'
├── category: 'functional' | 'ui' | 'performance' | 'security' | 'compatibility' | 'crash' | 'other'
├── status: 'new' | 'confirmed' | 'in_progress' | 'resolved' | 'closed' | 'duplicate' | 'wont_fix'
├── environment: Map
│   ├── device: Map
│   │   ├── brand: string
│   │   ├── model: string
│   │   ├── osVersion: string
│   │   ├── screenSize: string
│   │   └── resolution: string
│   ├── app: Map
│   │   ├── version: string
│   │   ├── build: string
│   │   └── installMethod: string
│   └── network: Map
│       ├── type: 'wifi' | 'cellular' | 'offline'
│       ├── speed: string (optional)
│       └── provider: string (optional)
├── reproduction: Map
│   ├── steps: array<string>
│   ├── expectedResult: string
│   ├── actualResult: string
│   ├── frequency: 'always' | 'sometimes' | 'rarely' | 'once'
│   └── isReproducible: boolean
├── attachments: array<Map>
│   ├── id: string
│   ├── type: 'image' | 'video' | 'log' | 'crash_dump'
│   ├── url: string
│   ├── thumbnail: string (optional)
│   ├── size: number
│   ├── name: string
│   └── uploadedAt: Timestamp
├── location: Map (optional)
│   ├── screen: string
│   ├── feature: string
│   ├── coordinates: Map
│   │   ├── x: number
│   │   └── y: number
│   └── elementId: string (optional)
├── impact: Map
│   ├── usersAffected: 'few' | 'some' | 'many' | 'all'
│   ├── businessImpact: 'low' | 'medium' | 'high' | 'critical'
│   └── workaround: string (optional)
├── resolution: Map (optional)
│   ├── resolvedAt: Timestamp
│   ├── resolvedBy: string (reference to users/{userId})
│   ├── resolution: string
│   ├── fixVersion: string (optional)
│   └── verifiedBy: string (reference to users/{userId}) (optional)
├── tracking: Map
│   ├── views: number
│   ├── votes: number
│   ├── duplicates: array<string> (reference to bug_reports/{reportId})
│   └── relatedReports: array<string> (reference to bug_reports/{reportId})
├── assignee: string (reference to users/{userId}) (optional)
├── labels: array<string>
├── submittedAt: Timestamp
├── updatedAt: Timestamp
└── closedAt: Timestamp (optional)
```

### 8. payments
결제 및 정산 정보
```
payments/{paymentId}
├── userId: string (reference to users/{userId})
├── userType: 'tester' | 'provider'
├── type: 'earning' | 'payment' | 'refund' | 'fee' | 'bonus'
├── status: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'
├── amount: number
├── currency: string
├── description: string
├── relatedId: string (reference to missions/{missionId} or mission_applications/{applicationId})
├── paymentMethod: Map
│   ├── type: 'bank_transfer' | 'paypal' | 'stripe' | 'points'
│   ├── details: Map (encrypted)
│   └── lastFourDigits: string (optional)
├── transaction: Map
│   ├── externalId: string (optional)
│   ├── fees: number
│   ├── netAmount: number
│   └── exchangeRate: number (optional)
├── metadata: Map
│   ├── missionTitle: string (optional)
│   ├── originalCurrency: string (optional)
│   ├── originalAmount: number (optional)
│   └── notes: string (optional)
├── createdAt: Timestamp
├── processedAt: Timestamp (optional)
├── completedAt: Timestamp (optional)
└── updatedAt: Timestamp
```

### 9. notifications
알림 정보
```
notifications/{notificationId}
├── userId: string (reference to users/{userId})
├── type: 'mission' | 'payment' | 'system' | 'marketing'
├── category: 'new_mission' | 'mission_update' | 'payment_received' | 'bug_report' | 'system_maintenance'
├── title: string
├── message: string
├── data: Map (optional)
│   ├── missionId: string (optional)
│   ├── appId: string (optional)
│   ├── reportId: string (optional)
│   ├── paymentId: string (optional)
│   └── actionUrl: string (optional)
├── channels: Map
│   ├── push: boolean
│   ├── email: boolean
│   ├── sms: boolean
│   └── inApp: boolean
├── status: Map
│   ├── sent: boolean
│   ├── delivered: boolean
│   ├── read: boolean
│   └── clicked: boolean
├── priority: 'low' | 'medium' | 'high' | 'urgent'
├── scheduledFor: Timestamp (optional)
├── expiresAt: Timestamp (optional)
├── createdAt: Timestamp
├── sentAt: Timestamp (optional)
├── readAt: Timestamp (optional)
└── updatedAt: Timestamp
```

### 10. analytics_events
분석 이벤트 정보
```
analytics_events/{eventId}
├── userId: string (reference to users/{userId}) (optional)
├── sessionId: string
├── eventType: string
├── eventName: string
├── properties: Map
├── userAgent: string (optional)
├── ipAddress: string (hashed)
├── location: Map (optional)
│   ├── country: string
│   ├── region: string
│   └── city: string
├── device: Map (optional)
│   ├── platform: string
│   ├── deviceType: string
│   └── screenSize: string
├── timestamp: Timestamp
└── processed: boolean
```

## Security Rules Structure

### Authentication Requirements
- All users must be authenticated
- Users can only access their own data
- Providers can access their missions and related bug reports
- Testers can access missions they applied for
- Admin users have elevated permissions

### Data Validation
- All timestamps are server-generated
- Sensitive data (payment info) is encrypted
- Email validation for user accounts
- Phone number validation for international format

### Performance Optimization
- Compound indexes for common queries
- Pagination for large collections
- Caching for frequently accessed data
- Background functions for complex operations