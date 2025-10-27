// Create SYSTEM_ESCROW wallet in Firestore
// Run this script once to initialize the escrow wallet

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'bugcash',
});

const db = admin.firestore();

async function createEscrowWallet() {
  const ESCROW_ACCOUNT_ID = 'SYSTEM_ESCROW';

  try {
    console.log('🔍 Checking if SYSTEM_ESCROW wallet already exists...');

    const walletRef = db.collection('wallets').doc(ESCROW_ACCOUNT_ID);
    const walletDoc = await walletRef.get();

    if (walletDoc.exists) {
      console.log('✅ SYSTEM_ESCROW wallet already exists');
      console.log('Current data:', walletDoc.data());
      return;
    }

    console.log('📝 Creating SYSTEM_ESCROW wallet...');

    const walletData = {
      userId: ESCROW_ACCOUNT_ID,
      balance: 0,
      totalCharged: 0,
      totalEarned: 0,
      totalSpent: 0,
      totalWithdrawn: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await walletRef.set(walletData);

    console.log('✅ SYSTEM_ESCROW wallet created successfully!');
    console.log('Wallet data:', walletData);

    // Verify creation
    const verifyDoc = await walletRef.get();
    if (verifyDoc.exists) {
      console.log('✅ Verification passed: Wallet exists in Firestore');
      console.log('Final data:', verifyDoc.data());
    } else {
      console.error('❌ Verification failed: Wallet not found after creation');
    }

  } catch (error) {
    console.error('❌ Error creating SYSTEM_ESCROW wallet:', error);
    throw error;
  }
}

// Run the script
createEscrowWallet()
  .then(() => {
    console.log('\n🎉 Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Script failed:', error);
    process.exit(1);
  });
