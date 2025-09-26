// 기존 Firebase Auth 사용자들에 대한 Firestore 문서 생성 스크립트
// Firebase Console에서 직접 실행하거나 Node.js로 실행 가능

const usersToFix = [
  {
    uid: 'pmkoZCAE7LOfIIdQ0v6A6WPKzif2',
    email: 'admin@bugcash.com',
    displayName: '관리자',
    role: 'admin'  // 관리자로 설정
  },
  {
    uid: '3Ud1QbdDuwbfKZqa0QlcSioMYN72',
    email: 'admin2@bugcash.com',
    displayName: '관리자2',
    role: 'admin'  // 관리자로 설정
  }
];

// Firebase Console의 개발자 콘솔에서 실행할 코드
usersToFix.forEach(async (user) => {
  await db.collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    role: user.role,
    userType: user.role === 'admin' ? 'admin' : user.role,
    country: 'KR',
    timezone: 'Asia/Seoul',
    phoneNumber: null,
    photoURL: null,
    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: firebase.firestore.FieldValue.serverTimestamp(),
    isActive: true
  }, { merge: true });

  console.log(`Created/Updated user document for ${user.email}`);
});