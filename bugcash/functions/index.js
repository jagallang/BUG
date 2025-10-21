const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentUpdated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

/**
 * Helper Functions
 */

// Check if user is admin (v2.72.0: primaryRole/roles 배열 체크)
async function isAdmin(uid) {
  if (!uid) return false;
  try {
    const userDoc = await getFirestore().collection("users").doc(uid).get();
    if (!userDoc.exists) return false;

    const userData = userDoc.data();
    // primaryRole 또는 roles 배열에서 admin 확인
    return userData.primaryRole === "admin" ||
           (userData.roles && userData.roles.includes("admin"));
  } catch (error) {
    console.error("Error checking admin role:", error);
    return false;
  }
}

// Check if user is provider and owns the project
async function isProjectProvider(uid, projectId) {
  if (!uid || !projectId) return false;
  try {
    const projectDoc = await getFirestore().collection("projects").doc(projectId).get();
    return projectDoc.exists && projectDoc.data().providerId === uid;
  } catch (error) {
    console.error("Error checking project provider:", error);
    return false;
  }
}

// Validate state transition
function isValidTransition(currentStatus, newStatus) {
  const validTransitions = {
    "draft": ["pending", "closed"],
    "pending": ["open", "rejected"],
    "open": ["closed"],
    "rejected": ["pending"], // Allow resubmission
    "closed": [], // Terminal state
  };

  return validTransitions[currentStatus]?.includes(newStatus) || false;
}

/**
 * Submit Project: draft → pending
 * Only project providers can submit their own projects
 */
exports.submitProject = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {projectId} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  if (!projectId) {
    throw new HttpsError("invalid-argument", "Project ID is required");
  }

  // Check if user is the project provider
  const isProvider = await isProjectProvider(uid, projectId);
  if (!isProvider) {
    throw new HttpsError(
        "permission-denied",
        "Only project providers can submit their projects",
    );
  }

  try {
    const projectRef = getFirestore().collection("projects").doc(projectId);
    const projectDoc = await projectRef.get();

    if (!projectDoc.exists) {
      throw new HttpsError("not-found", "Project not found");
    }

    const currentStatus = projectDoc.data().status;

    // Validate transition
    if (!isValidTransition(currentStatus, "pending")) {
      throw new HttpsError(
          "failed-precondition",
          `Cannot transition from ${currentStatus} to pending`,
      );
    }

    // Update project status
    await projectRef.update({
      status: "pending",
      submittedAt: FieldValue.serverTimestamp(),
      submittedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(`Project ${projectId} submitted by ${uid}`);
    return {success: true, message: "Project submitted successfully"};
  } catch (error) {
    console.error("Error submitting project:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to submit project");
  }
});

/**
 * Review Project: pending → open/rejected
 * Only admins can review projects
 */
exports.reviewProject = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {projectId, approve, rejectionReason} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  if (!projectId || typeof approve !== "boolean") {
    throw new HttpsError(
        "invalid-argument",
        "Project ID and approve status are required",
    );
  }

  // Check if user is admin
  const adminCheck = await isAdmin(uid);
  if (!adminCheck) {
    throw new HttpsError("permission-denied", "Only admins can review projects");
  }

  try {
    const projectRef = getFirestore().collection("projects").doc(projectId);
    const projectDoc = await projectRef.get();

    if (!projectDoc.exists) {
      throw new HttpsError("not-found", "Project not found");
    }

    const currentStatus = projectDoc.data().status;
    const newStatus = approve ? "open" : "rejected";

    // Validate transition
    if (!isValidTransition(currentStatus, newStatus)) {
      throw new HttpsError(
          "failed-precondition",
          `Cannot transition from ${currentStatus} to ${newStatus}`,
      );
    }

    // Prepare update data
    const updateData = {
      status: newStatus,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (approve) {
      updateData.approvedAt = FieldValue.serverTimestamp();
      updateData.approvedBy = uid;
    } else {
      updateData.rejectedAt = FieldValue.serverTimestamp();
      updateData.rejectedBy = uid;
      if (rejectionReason) {
        updateData.rejectionReason = rejectionReason;
      }
    }

    // Update project status
    await projectRef.update(updateData);

    const action = approve ? "approved" : "rejected";
    console.log(`Project ${projectId} ${action} by admin ${uid}`);

    return {
      success: true,
      message: `Project ${action} successfully`,
      newStatus: newStatus,
    };
  } catch (error) {
    console.error("Error reviewing project:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to review project");
  }
});

/**
 * Close Project: open → closed
 * Admins or project providers can close projects
 */
exports.closeProject = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {projectId, reason} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  if (!projectId) {
    throw new HttpsError("invalid-argument", "Project ID is required");
  }

  // Check permissions
  const adminCheck = await isAdmin(uid);
  const providerCheck = await isProjectProvider(uid, projectId);

  if (!adminCheck && !providerCheck) {
    throw new HttpsError(
        "permission-denied",
        "Only admins or project providers can close projects",
    );
  }

  try {
    const projectRef = getFirestore().collection("projects").doc(projectId);
    const projectDoc = await projectRef.get();

    if (!projectDoc.exists) {
      throw new HttpsError("not-found", "Project not found");
    }

    const currentStatus = projectDoc.data().status;

    // Validate transition
    if (!isValidTransition(currentStatus, "closed")) {
      throw new HttpsError(
          "failed-precondition",
          `Cannot transition from ${currentStatus} to closed`,
      );
    }

    // Update project status
    await projectRef.update({
      status: "closed",
      closedAt: FieldValue.serverTimestamp(),
      closedBy: uid,
      closureReason: reason || "Project completed",
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(`Project ${projectId} closed by ${uid}`);
    return {success: true, message: "Project closed successfully"};
  } catch (error) {
    console.error("Error closing project:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to close project");
  }
});

/**
 * Project Status Change Trigger
 * Handles side effects when project status changes
 */
exports.onProjectStatusChange = onDocumentUpdated(
    "projects/{projectId}",
    async (event) => {
      const projectId = event.params.projectId;
      const beforeData = event.data?.before?.data();
      const afterData = event.data?.after?.data();

      if (!beforeData || !afterData) {
        console.log("No data found for project status change");
        return;
      }

      const oldStatus = beforeData.status;
      const newStatus = afterData.status;

      // Only process if status actually changed
      if (oldStatus === newStatus) {
        console.log("Status unchanged, skipping processing");
        return;
      }

      console.log(
          `Project ${projectId} status changed: ${oldStatus} → ${newStatus}`,
      );

      try {
        // Handle different status transitions
        if (newStatus === "open") {
          await handleProjectApproved(projectId, afterData);
        } else if (newStatus === "rejected") {
          await handleProjectRejected(projectId, afterData);
        } else if (newStatus === "closed") {
          await handleProjectClosed(projectId, afterData);
        }
      } catch (error) {
        console.error(
            `Error handling status change for project ${projectId}:`,
            error,
        );
      }
    },
);

/**
 * Handle Project Approved (open status)
 */
async function handleProjectApproved(projectId, projectData) {
  console.log(`Handling approval for project ${projectId}`);

  // Create notification for project provider
  await getFirestore().collection("notifications").add({
    userId: projectData.providerId,
    type: "project_approved",
    title: "프로젝트 승인됨",
    message: `프로젝트 "${projectData.appName}"이 승인되었습니다.`,
    projectId: projectId,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Additional logic can be added here
  // - Enable applications for this project
  // - Send email notifications
  // - Update analytics/metrics
}

/**
 * Handle Project Rejected
 */
async function handleProjectRejected(projectId, projectData) {
  console.log(`Handling rejection for project ${projectId}`);

  // Create notification for project provider
  await getFirestore().collection("notifications").add({
    userId: projectData.providerId,
    type: "project_rejected",
    title: "프로젝트 거부됨",
    message: `프로젝트 "${projectData.appName}"이 거부되었습니다.`,
    projectId: projectId,
    rejectionReason: projectData.rejectionReason || "사유 없음",
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Cancel any pending applications
  await cancelPendingApplications(projectId);
}

/**
 * Handle Project Closed
 */
async function handleProjectClosed(projectId, projectData) {
  console.log(`Handling closure for project ${projectId}`);

  // Create notification for project provider
  await getFirestore().collection("notifications").add({
    userId: projectData.providerId,
    type: "project_closed",
    title: "프로젝트 종료됨",
    message: `프로젝트 "${projectData.appName}"이 종료되었습니다.`,
    projectId: projectId,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Close active enrollments
  await closeActiveEnrollments(projectId);

  // Process final payouts
  await processFinalPayouts(projectId);
}

/**
 * Helper function to cancel pending applications
 */
async function cancelPendingApplications(projectId) {
  const applicationsRef = getFirestore().collection("applications");
  const pendingApplications = await applicationsRef
      .where("projectId", "==", projectId)
      .where("status", "==", "pending")
      .get();

  const batch = getFirestore().batch();
  pendingApplications.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp(),
      cancelReason: "Project rejected",
    });
  });

  if (!pendingApplications.empty) {
    await batch.commit();
    console.log(`Cancelled ${pendingApplications.size} pending applications`);
  }
}

/**
 * Helper function to close active enrollments
 */
async function closeActiveEnrollments(projectId) {
  const enrollmentsRef = getFirestore().collection("enrollments");
  const activeEnrollments = await enrollmentsRef
      .where("projectId", "==", projectId)
      .where("status", "==", "active")
      .get();

  const batch = getFirestore().batch();
  activeEnrollments.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
      completionReason: "Project closed",
    });
  });

  if (!activeEnrollments.empty) {
    await batch.commit();
    console.log(`Closed ${activeEnrollments.size} active enrollments`);
  }
}

/**
 * Helper function to process final payouts
 */
async function processFinalPayouts(projectId) {
  // This would integrate with your payment processing system
  // For now, just log the action
  console.log(`Processing final payouts for project ${projectId}`);

  // TODO: Implement actual payout logic
  // - Calculate final rewards
  // - Process payments to testers
  // - Update point balances
  // - Create transaction records
}

/**
 * ==========================================
 * Payment & Wallet Security Functions
 * ==========================================
 */

/**
 * Verify Toss Payment Server-Side
 * 결제 검증을 서버에서 수행하여 위변조 방지
 */
exports.verifyTossPayment = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {paymentKey, orderId, amount, userId} = request.data;
  const uid = request.auth?.uid;

  // Authentication check
  if (!uid || uid !== userId) {
    throw new HttpsError("permission-denied", "Invalid user authentication");
  }

  if (!paymentKey || !orderId || !amount) {
    throw new HttpsError("invalid-argument", "Missing payment verification data");
  }

  try {
    // 1. Toss Payments API로 결제 검증
    const tossSecretKey = process.env.TOSS_SECRET_KEY;
    if (!tossSecretKey) {
      throw new HttpsError("internal", "Toss secret key not configured");
    }

    const response = await fetch(
        `https://api.tosspayments.com/v1/payments/${paymentKey}`,
        {
          method: "GET",
          headers: {
            "Authorization": `Basic ${Buffer.from(tossSecretKey + ":").toString("base64")}`,
            "Content-Type": "application/json",
          },
        },
    );

    if (!response.ok) {
      throw new HttpsError("internal", "Failed to verify payment with Toss");
    }

    const paymentData = await response.json();

    // 2. 결제 데이터 검증
    if (paymentData.orderId !== orderId) {
      throw new HttpsError("failed-precondition", "Order ID mismatch");
    }

    if (paymentData.totalAmount !== amount) {
      throw new HttpsError("failed-precondition", "Amount mismatch");
    }

    if (paymentData.status !== "DONE") {
      throw new HttpsError("failed-precondition", "Payment not completed");
    }

    // 3. 중복 결제 확인
    const existingTransaction = await getFirestore()
        .collection("transactions")
        .where("metadata.paymentKey", "==", paymentKey)
        .limit(1)
        .get();

    if (!existingTransaction.empty) {
      throw new HttpsError("already-exists", "Payment already processed");
    }

    // 4. 트랜잭션으로 지갑 잔액 업데이트
    const pointsEarned = Math.floor(amount); // 1원 = 1포인트
    const db = getFirestore();

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection("wallets").doc(userId);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        // 지갑이 없으면 생성
        transaction.set(walletRef, {
          userId: userId,
          balance: pointsEarned,
          totalCharged: pointsEarned,
          totalEarned: 0,
          totalSpent: 0,
          totalWithdrawn: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        // 기존 지갑 업데이트
        const currentBalance = walletDoc.data().balance || 0;
        const currentTotalCharged = walletDoc.data().totalCharged || 0;

        transaction.update(walletRef, {
          balance: currentBalance + pointsEarned,
          totalCharged: currentTotalCharged + pointsEarned,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      // 5. 거래 내역 생성
      const transactionRef = db.collection("transactions").doc();
      transaction.set(transactionRef, {
        userId: userId,
        type: "charge",
        amount: pointsEarned,
        status: "completed",
        description: `포인트 충전 ${pointsEarned.toLocaleString()}P`,
        metadata: {
          paymentKey: paymentKey,
          orderId: orderId,
          paymentAmount: amount,
          paymentMethod: paymentData.method,
          approvedAt: paymentData.approvedAt,
        },
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    console.log(`Payment verified and ${pointsEarned}P credited to user ${userId}`);

    return {
      success: true,
      pointsEarned: pointsEarned,
      message: "Payment verified and points credited",
    };
  } catch (error) {
    console.error("Payment verification error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Payment verification failed");
  }
});

/**
 * Validate Wallet Transaction
 * 포인트 거래 전 검증 (잔액 확인, 한도 확인 등)
 */
exports.validateWalletTransaction = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId, type, amount} = request.data;
  const uid = request.auth?.uid;

  if (!uid || uid !== userId) {
    throw new HttpsError("permission-denied", "Invalid user authentication");
  }

  if (!type || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid transaction data");
  }

  try {
    const walletDoc = await getFirestore()
        .collection("wallets")
        .doc(userId)
        .get();

    if (!walletDoc.exists) {
      throw new HttpsError("not-found", "Wallet not found");
    }

    const wallet = walletDoc.data();
    const balance = wallet.balance || 0;

    // 출금/사용 시 잔액 확인
    if (type === "spend" || type === "withdraw") {
      if (balance < amount) {
        return {
          valid: false,
          reason: "insufficient_balance",
          message: `잔액 부족 (잔액: ${balance}P, 필요: ${amount}P)`,
          currentBalance: balance,
          requiredAmount: amount,
        };
      }

      // 출금 한도 확인 (일일 100만원)
      if (type === "withdraw") {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const todayWithdrawals = await getFirestore()
            .collection("transactions")
            .where("userId", "==", userId)
            .where("type", "==", "withdraw")
            .where("createdAt", ">=", today)
            .get();

        const todayTotal = todayWithdrawals.docs.reduce(
            (sum, doc) => sum + (doc.data().amount || 0),
            0,
        );

        const withdrawalLimit = 1000000; // 100만원
        if (todayTotal + amount > withdrawalLimit) {
          return {
            valid: false,
            reason: "daily_limit_exceeded",
            message: `일일 출금 한도 초과 (오늘 출금: ${todayTotal}P, 한도: ${withdrawalLimit}P)`,
            todayTotal: todayTotal,
            limit: withdrawalLimit,
          };
        }
      }
    }

    return {
      valid: true,
      currentBalance: balance,
      message: "Transaction validation passed",
    };
  } catch (error) {
    console.error("Transaction validation error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Transaction validation failed");
  }
});

/**
 * Process Withdrawal Request with Admin Approval
 * 출금 신청은 관리자 승인 필요
 */
exports.processWithdrawal = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {transactionId, approve, rejectionReason} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 관리자 권한 확인
  const adminCheck = await isAdmin(uid);
  if (!adminCheck) {
    throw new HttpsError("permission-denied", "Only admins can process withdrawals");
  }

  if (!transactionId || typeof approve !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid request parameters");
  }

  try {
    const db = getFirestore();

    await db.runTransaction(async (transaction) => {
      const txRef = db.collection("transactions").doc(transactionId);
      const txDoc = await transaction.get(txRef);

      if (!txDoc.exists) {
        throw new HttpsError("not-found", "Transaction not found");
      }

      const txData = txDoc.data();

      if (txData.type !== "withdraw") {
        throw new HttpsError("invalid-argument", "Not a withdrawal transaction");
      }

      if (txData.status !== "pending") {
        throw new HttpsError("failed-precondition", "Transaction already processed");
      }

      // 승인 처리
      if (approve) {
        transaction.update(txRef, {
          status: "completed",
          processedAt: FieldValue.serverTimestamp(),
          processedBy: uid,
        });

        console.log(`Withdrawal ${transactionId} approved by admin ${uid}`);
      } else {
        // 거부 시 잔액 복구
        const walletRef = db.collection("wallets").doc(txData.userId);
        const walletDoc = await transaction.get(walletRef);

        if (walletDoc.exists) {
          const currentBalance = walletDoc.data().balance || 0;
          transaction.update(walletRef, {
            balance: currentBalance + txData.amount,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        transaction.update(txRef, {
          status: "cancelled",
          processedAt: FieldValue.serverTimestamp(),
          processedBy: uid,
          rejectionReason: rejectionReason || "관리자가 거부함",
        });

        console.log(`Withdrawal ${transactionId} rejected by admin ${uid}`);
      }
    });

    return {
      success: true,
      message: approve ? "Withdrawal approved" : "Withdrawal rejected",
    };
  } catch (error) {
    console.error("Withdrawal processing error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to process withdrawal");
  }
});

/**
 * Monitor Suspicious Transactions
 * 의심스러운 거래 모니터링 (Firestore Trigger)
 */
exports.onTransactionCreated = onDocumentUpdated(
    "transactions/{transactionId}",
    async (event) => {
      const transactionId = event.params.transactionId;
      const afterData = event.data?.after?.data();

      if (!afterData) return;

      try {
        // 비정상적으로 큰 금액 체크
        if (afterData.amount > 10000000) { // 1000만원 초과
          console.warn(`⚠️ Large transaction detected: ${transactionId}, amount: ${afterData.amount}`);

          await getFirestore().collection("alerts").add({
            type: "large_transaction",
            transactionId: transactionId,
            userId: afterData.userId,
            amount: afterData.amount,
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        // 짧은 시간 내 다수 거래 체크
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        const recentTransactions = await getFirestore()
            .collection("transactions")
            .where("userId", "==", afterData.userId)
            .where("createdAt", ">=", fiveMinutesAgo)
            .get();

        if (recentTransactions.size > 10) {
          console.warn(`⚠️ Rapid transactions detected: User ${afterData.userId}, count: ${recentTransactions.size}`);

          await getFirestore().collection("alerts").add({
            type: "rapid_transactions",
            userId: afterData.userId,
            transactionCount: recentTransactions.size,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
        console.error("Transaction monitoring error:", error);
      }
    },
);

/**
 * Charge Wallet (포인트 충전)
 * 서버 검증을 통한 안전한 지갑 잔액 업데이트
 */
exports.chargeWallet = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId, amount, description, metadata} = request.data;
  const uid = request.auth?.uid;

  // 1. 인증 확인
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. 본인 지갑만 충전 가능
  if (uid !== userId) {
    throw new HttpsError("permission-denied", "Can only charge own wallet");
  }

  // 3. 금액 검증
  if (!amount || typeof amount !== "number" || amount < 1000) {
    throw new HttpsError(
        "invalid-argument",
        "Amount must be at least 1000",
    );
  }

  if (amount > 10000000) {
    throw new HttpsError(
        "invalid-argument",
        "Amount must not exceed 10,000,000",
    );
  }

  // 4. orderId 중복 체크 (Mock 제외)
  const orderId = metadata?.orderId;
  if (orderId && !orderId.startsWith("mock_")) {
    const existingTx = await getFirestore()
        .collection("transactions")
        .where("metadata.orderId", "==", orderId)
        .where("status", "==", "completed")
        .limit(1)
        .get();

    if (!existingTx.empty) {
      throw new HttpsError(
          "already-exists",
          "Payment already processed (duplicate orderId)",
      );
    }
  }

  try {
    // 5. Firestore Transaction으로 원자적 업데이트
    await getFirestore().runTransaction(async (transaction) => {
      const walletRef = getFirestore().collection("wallets").doc(userId);
      const walletDoc = await transaction.get(walletRef);

      // 지갑이 없으면 자동 생성
      if (!walletDoc.exists) {
        transaction.set(walletRef, {
          userId: userId,
          balance: 0,
          totalCharged: 0,
          totalSpent: 0,
          totalEarned: 0,
          totalWithdrawn: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      const currentBalance = walletDoc.exists ? walletDoc.data().balance : 0;
      const newBalance = currentBalance + amount;

      // 지갑 업데이트
      transaction.update(walletRef, {
        balance: newBalance,
        totalCharged: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 거래 내역 생성
      const transactionRef = getFirestore().collection("transactions").doc();
      transaction.set(transactionRef, {
        userId: userId,
        type: "charge",
        amount: amount,
        status: "completed",
        description: description || "포인트 충전",
        metadata: metadata || {},
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      console.log(`Wallet charged: userId=${userId}, amount=${amount}`);
    });

    return {
      success: true,
      message: "Wallet charged successfully",
    };
  } catch (error) {
    console.error("Error charging wallet:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to charge wallet");
  }
});

/**
 * suspendUser: 사용자 계정 일시정지/해제 (v2.58.0)
 * Only admins can suspend/unsuspend user accounts
 */
exports.suspendUser = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId, suspend, reason, durationDays} = request.data;
  const adminUid = request.auth?.uid;

  // 1. Authentication check
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. Admin check
  const isAdminUser = await isAdmin(adminUid);
  if (!isAdminUser) {
    throw new HttpsError("permission-denied", "Only admins can suspend users");
  }

  // 3. Validation
  if (!userId) {
    throw new HttpsError("invalid-argument", "User ID is required");
  }

  if (suspend === undefined || typeof suspend !== "boolean") {
    throw new HttpsError("invalid-argument", "Suspend flag must be boolean");
  }

  // 관리자 자신을 정지할 수 없음
  if (userId === adminUid) {
    throw new HttpsError("permission-denied", "Cannot suspend your own account");
  }

  try {
    const userRef = getFirestore().collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const updateData = {
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (suspend) {
      // 계정 정지
      const suspendUntil = durationDays && durationDays > 0
          ? new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000)
          : null; // null = 영구 정지

      updateData.isSuspended = true;
      updateData.suspendedAt = FieldValue.serverTimestamp();
      updateData.suspendedBy = adminUid;
      updateData.suspendReason = reason || "No reason provided";
      if (suspendUntil) {
        updateData.suspendUntil = suspendUntil;
      }

      console.log(`🔴 Admin ${adminUid} suspended user ${userId} - ` +
                  `Reason: ${reason} - Duration: ${durationDays ? durationDays + " days" : "permanent"}`);
    } else {
      // 계정 정지 해제
      updateData.isSuspended = false;
      updateData.suspendedAt = null;
      updateData.suspendedBy = null;
      updateData.suspendReason = null;
      updateData.suspendUntil = null;

      console.log(`✅ Admin ${adminUid} unsuspended user ${userId}`);
    }

    await userRef.update(updateData);

    return {
      success: true,
      message: suspend ?
        `User ${userId} has been suspended` :
        `User ${userId} has been unsuspended`,
      userId: userId,
      isSuspended: suspend,
    };
  } catch (error) {
    console.error("Error suspending/unsuspending user:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to suspend/unsuspend user");
  }
});

/**
 * adjustUserPoints: 관리자가 사용자 포인트/지갑 잔액 조정 (v2.58.0)
 * Admin can grant, deduct, or reset user points and wallet balance
 */
exports.adjustUserPoints = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId, adjustmentType, amount, reason} = request.data;
  const adminUid = request.auth?.uid;

  // 1. Authentication check
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. Admin check
  const isAdminUser = await isAdmin(adminUid);
  if (!isAdminUser) {
    throw new HttpsError("permission-denied", "Only admins can adjust user points");
  }

  // 3. Validation
  if (!userId) {
    throw new HttpsError("invalid-argument", "User ID is required");
  }

  if (!adjustmentType || !["grant", "deduct", "reset"].includes(adjustmentType)) {
    throw new HttpsError("invalid-argument",
        "Adjustment type must be 'grant', 'deduct', or 'reset'");
  }

  if (adjustmentType !== "reset") {
    if (!amount || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument",
          "Amount must be a positive number for grant/deduct");
    }
  }

  try {
    const userRef = getFirestore().collection("users").doc(userId);
    const walletRef = getFirestore().collection("wallets").doc(userId);

    await getFirestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const walletDoc = await transaction.get(walletRef);

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "User not found");
      }

      const userData = userDoc.data();
      const currentPoints = userData.points || 0;

      // 지갑이 없으면 생성
      if (!walletDoc.exists) {
        transaction.set(walletRef, {
          userId: userId,
          balance: 0,
          totalCharged: 0,
          totalEarned: 0,
          totalSpent: 0,
          totalWithdrawn: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      const walletData = walletDoc.exists ? walletDoc.data() : {balance: 0};
      const currentBalance = walletData.balance || 0;

      let newPoints = currentPoints;
      let newBalance = currentBalance;
      let walletUpdate = {};
      let logMessage = "";

      switch (adjustmentType) {
        case "grant":
          // 포인트 지급
          newPoints = currentPoints + amount;
          newBalance = currentBalance + amount;
          walletUpdate = {
            balance: newBalance,
            totalEarned: FieldValue.increment(amount),
            updatedAt: FieldValue.serverTimestamp(),
          };
          logMessage = `Admin granted ${amount}P - Reason: ${reason || "No reason"}`;
          break;

        case "deduct":
          // 포인트 차감
          newPoints = Math.max(0, currentPoints - amount);
          newBalance = Math.max(0, currentBalance - amount);
          walletUpdate = {
            balance: newBalance,
            totalSpent: FieldValue.increment(amount),
            updatedAt: FieldValue.serverTimestamp(),
          };
          logMessage = `Admin deducted ${amount}P - Reason: ${reason || "No reason"}`;
          break;

        case "reset":
          // 포인트 리셋 (0으로 초기화)
          newPoints = 0;
          newBalance = 0;
          walletUpdate = {
            balance: 0,
            updatedAt: FieldValue.serverTimestamp(),
          };
          logMessage = `Admin reset points to 0 - Reason: ${reason || "No reason"}`;
          break;
      }

      // User points 업데이트
      transaction.update(userRef, {
        points: newPoints,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Wallet balance 업데이트
      transaction.update(walletRef, walletUpdate);

      // 거래 내역 기록 (관리자 조정)
      const transactionRef = getFirestore().collection("transactions").doc();
      transaction.set(transactionRef, {
        userId: userId,
        type: "admin_adjustment",
        amount: adjustmentType === "reset" ? currentBalance : amount,
        adjustmentType: adjustmentType,
        status: "completed",
        description: `관리자 포인트 조정: ${adjustmentType}`,
        metadata: {
          adminId: adminUid,
          reason: reason || "No reason provided",
          previousPoints: currentPoints,
          newPoints: newPoints,
          previousBalance: currentBalance,
          newBalance: newBalance,
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      console.log(`💰 ${logMessage} - User: ${userId} - Admin: ${adminUid}`);
    });

    return {
      success: true,
      message: `User ${userId} points adjusted successfully`,
      userId: userId,
      adjustmentType: adjustmentType,
      amount: adjustmentType === "reset" ? null : amount,
    };
  } catch (error) {
    console.error("Error adjusting user points:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to adjust user points");
  }
});

/**
 * getPlatformSettings: 플랫폼 설정 조회 (v2.59.0)
 * Anyone can read settings
 */
exports.getPlatformSettings = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {settingType} = request.data;

  // Validate setting type
  const validTypes = ["rewards", "withdrawal", "platform", "abuse_prevention"];
  if (!settingType || !validTypes.includes(settingType)) {
    throw new HttpsError("invalid-argument", "Invalid setting type");
  }

  try {
    const settingDoc = await getFirestore()
        .collection("platform_settings")
        .doc(settingType)
        .get();

    if (!settingDoc.exists) {
      // Return default settings
      return getDefaultSettings(settingType);
    }

    return settingDoc.data();
  } catch (error) {
    console.error("Error getting settings:", error);
    throw new HttpsError("internal", "Failed to get settings");
  }
});

/**
 * updatePlatformSettings: 플랫폼 설정 업데이트 (v2.59.0)
 * Admin only
 */
exports.updatePlatformSettings = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {settingType, updates, reason} = request.data;
  const adminUid = request.auth?.uid;

  // Authentication & Authorization
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const isAdminUser = await isAdmin(adminUid);
  if (!isAdminUser) {
    throw new HttpsError("permission-denied", "Only admins can update settings");
  }

  // Validation
  const validTypes = ["rewards", "withdrawal", "platform", "abuse_prevention"];
  if (!settingType || !validTypes.includes(settingType)) {
    throw new HttpsError("invalid-argument", "Invalid setting type");
  }

  if (!updates || typeof updates !== "object") {
    throw new HttpsError("invalid-argument", "Updates must be an object");
  }

  try {
    const settingRef = getFirestore()
        .collection("platform_settings")
        .doc(settingType);

    await getFirestore().runTransaction(async (transaction) => {
      const currentDoc = await transaction.get(settingRef);
      const currentData = currentDoc.data() || {};

      // Record change history for audit
      Object.keys(updates).forEach((key) => {
        const historyRef = getFirestore().collection("settings_history").doc();
        transaction.set(historyRef, {
          settingType,
          settingKey: key,
          oldValue: currentData[key],
          newValue: updates[key],
          changedBy: adminUid,
          changedAt: FieldValue.serverTimestamp(),
          reason: reason || "관리자 변경",
        });
      });

      // Update settings
      transaction.set(settingRef, {
        ...currentData,
        ...updates,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: adminUid,
      }, {merge: true});

      console.log(`✅ Settings updated: ${settingType} by admin ${adminUid}`);
    });

    return {
      success: true,
      message: "Settings updated successfully",
      settingType,
    };
  } catch (error) {
    console.error("Error updating settings:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to update settings");
  }
});

// Helper: Get default settings
function getDefaultSettings(type) {
  const defaults = {
    rewards: {
      signupBonus: {
        enabled: true,
        amount: 5000,
        description: "회원가입 축하 보너스",
        conditions: {
          requirePhoneVerification: false,
          requireEmailVerification: true,
          oneTimeOnly: true,
        },
      },
      projectCompletionBonus: {
        enabled: true,
        testerAmount: 1000,
        providerAmount: 1000,
        description: "14일 프로젝트 완료 보너스",
        conditions: {
          minDays: 14,
          requireAllDaysCompleted: true,
          oneTimePerProject: true,
        },
      },
      dailyMissionReward: {
        enabled: true,
        baseAmount: 50,
        description: "데일리 미션 기본 보상",
      },
    },
    withdrawal: {
      minAmount: 30000,
      allowedUnits: 10000,
      feeRate: 0.18,
      description: "출금 시 수수료로 차감됩니다",
      autoApprove: false,
      processingDays: 5,
      maxDailyWithdrawals: 3,
      maxMonthlyAmount: 10000000,
    },
    platform: {
      platformFee: {
        missionCreation: 0,
        transactionFee: 0.05,
      },
      appRegistration: {
        cost: 5000,
        description: "앱 등록 시 포인트로 차감",
      },
      missionCreation: {
        cost: 1000,
        description: "미션 생성 시 포인트로 차감",
      },
    },
    abuse_prevention: {
      multiAccountDetection: {
        enabled: true,
        checkDeviceId: true,
        checkIpAddress: true,
        maxAccountsPerDevice: 1,
        maxAccountsPerIp: 3,
      },
      withdrawalRestrictions: {
        requireKyc: true,
        minAccountAge: 7,
        minCompletedMissions: 1,
      },
    },
  };

  return defaults[type] || {};
}

/**
 * grantSignupBonus: 회원가입 보너스 자동 지급 (v2.61.0)
 * 회원가입 시 플랫폼 설정에 따라 환영 보너스 포인트 지급
 */
exports.grantSignupBonus = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId} = request.data;
  const adminUid = request.auth?.uid;

  // Authentication check
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Validate input
  if (!userId) {
    throw new HttpsError("invalid-argument", "userId is required");
  }

  // 본인 또는 관리자만 호출 가능
  const isAdminUser = await isAdmin(adminUid);
  if (adminUid !== userId && !isAdminUser) {
    throw new HttpsError(
        "permission-denied",
        "Only the user or admin can grant signup bonus",
    );
  }

  try {
    console.log(`회원가입 보너스 지급 시작: userId=${userId}`);

    // 1. 플랫폼 설정 로드
    const settingsDoc = await getFirestore()
        .collection("platform_settings")
        .doc("rewards")
        .get();

    let bonusAmount = 5000; // 기본값
    let bonusEnabled = true;

    if (settingsDoc.exists) {
      const settings = settingsDoc.data();
      bonusAmount = settings.signupBonus?.amount || 5000;
      bonusEnabled = settings.signupBonus?.enabled !== false;
    }

    console.log(`보너스 설정: enabled=${bonusEnabled}, amount=${bonusAmount}`);

    if (!bonusEnabled) {
      throw new HttpsError(
          "failed-precondition",
          "Signup bonus is currently disabled",
      );
    }

    // 2. 사용자 문서 확인 및 중복 지급 방지
    const userRef = getFirestore().collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();
    if (userData.signupBonusGranted === true) {
      throw new HttpsError(
          "already-exists",
          "Signup bonus already granted to this user",
      );
    }

    // 3. Firestore Transaction으로 지갑 생성 및 보너스 지급
    await getFirestore().runTransaction(async (transaction) => {
      const walletRef = getFirestore().collection("wallets").doc(userId);
      const walletDoc = await transaction.get(walletRef);

      let newBalance = bonusAmount;
      let newTotalEarned = bonusAmount;

      if (walletDoc.exists) {
        // 지갑이 이미 존재하면 업데이트
        const walletData = walletDoc.data();
        newBalance = (walletData.balance || 0) + bonusAmount;
        newTotalEarned = (walletData.totalEarned || 0) + bonusAmount;

        transaction.update(walletRef, {
          balance: newBalance,
          totalEarned: newTotalEarned,
          updatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        // 지갑이 없으면 새로 생성
        transaction.set(walletRef, {
          userId: userId,
          balance: newBalance,
          totalCharged: 0,
          totalEarned: newTotalEarned,
          totalSpent: 0,
          totalWithdrawn: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      // 4. transaction 기록 생성
      const transactionRef = getFirestore().collection("transactions").doc();
      transaction.set(transactionRef, {
        userId: userId,
        type: "signup_bonus",
        amount: bonusAmount,
        description: "회원가입 축하 보너스",
        status: "completed",
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          source: "grantSignupBonus",
          bonusType: "signup",
        },
      });

      // 5. 사용자 문서에 지급 완료 마킹
      transaction.update(userRef, {
        signupBonusGranted: true,
        signupBonusGrantedAt: FieldValue.serverTimestamp(),
      });

      console.log(`회원가입 보너스 지급 완료: userId=${userId}, amount=${bonusAmount}P`);
    });

    return {
      success: true,
      message: `회원가입 보너스 ${bonusAmount}P가 지급되었습니다.`,
      amount: bonusAmount,
    };
  } catch (error) {
    console.error("회원가입 보너스 지급 실패:", error);

    // HttpsError는 그대로 throw
    if (error instanceof HttpsError) {
      throw error;
    }

    // 기타 에러는 internal로 처리
    throw new HttpsError(
        "internal",
        `Failed to grant signup bonus: ${error.message}`,
    );
  }
});

/**
 * adminManageWallet: 관리자 전용 지갑 관리 함수 (v2.65.0)
 * Alias for adjustUserPoints with parameter name mapping for wallet management
 * actionType (add/subtract/reset) -> adjustmentType (grant/deduct/reset)
 */
exports.adminManageWallet = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {userId, actionType, amount, reason} = request.data;

  // Map actionType to adjustmentType
  const typeMapping = {
    'add': 'grant',
    'subtract': 'deduct',
    'reset': 'reset',
  };

  const adjustmentType = typeMapping[actionType];

  if (!adjustmentType) {
    throw new HttpsError("invalid-argument",
        "Action type must be 'add', 'subtract', or 'reset'");
  }

  // Call the existing adjustUserPoints function with mapped parameters
  const adjustRequest = {
    ...request,
    data: {
      userId,
      adjustmentType,
      amount,
      reason,
    },
  };

  return exports.adjustUserPoints.run(adjustRequest);
});

// ============================================================================
// v2.102.0: ESCROW SYSTEM - 에스크로 시스템
// ============================================================================

const ESCROW_ACCOUNT_ID = "SYSTEM_ESCROW";

/**
 * depositToEscrow - 앱 등록 시 공급자 포인트를 에스크로로 예치
 * @param {string} appId - 앱 ID
 * @param {string} providerId - 공급자 ID
 * @param {number} amount - 예치 금액
 * @param {object} breakdown - 금액 세부사항
 */
exports.depositToEscrow = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {appId, appName, providerId, providerName, amount, breakdown} = request.data;
  const uid = request.auth?.uid;

  // 인증 확인
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 공급자 본인 확인
  if (uid !== providerId) {
    throw new HttpsError("permission-denied", "You can only deposit for your own apps");
  }

  // 입력 검증
  if (!appId || !providerId || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid parameters");
  }

  try {
    return await getFirestore().runTransaction(async (transaction) => {
      // 1. 공급자 지갑 조회
      const providerWalletRef = getFirestore().collection("wallets").doc(providerId);
      const providerWallet = await transaction.get(providerWalletRef);

      if (!providerWallet.exists) {
        throw new HttpsError("not-found", "Provider wallet not found");
      }

      const providerBalance = providerWallet.data().balance || 0;

      // 2. 잔액 확인
      if (providerBalance < amount) {
        throw new HttpsError("failed-precondition", `Insufficient balance. Required: ${amount}, Available: ${providerBalance}`);
      }

      // 3. 에스크로 지갑 조회
      const escrowWalletRef = getFirestore().collection("wallets").doc(ESCROW_ACCOUNT_ID);
      const escrowWallet = await transaction.get(escrowWalletRef);

      if (!escrowWallet.exists) {
        throw new HttpsError("not-found", "Escrow wallet not found");
      }

      const escrowBalance = escrowWallet.data().balance || 0;

      // 4. 공급자 지갑 차감
      transaction.update(providerWalletRef, {
        balance: providerBalance - amount,
        totalSpent: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 5. 에스크로 지갑 증가
      transaction.update(escrowWalletRef, {
        balance: escrowBalance + amount,
        totalEarned: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 6. 공급자 거래 내역 생성
      const providerTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(providerTransactionRef, {
        userId: providerId,
        type: "spend",
        amount: amount,
        status: "completed",
        description: `앱 등록 에스크로 예치: ${appName}`,
        metadata: {
          appId: appId,
          appName: appName,
          escrowType: "deposit",
          ...breakdown,
          // v2.112.0: 리워드 시스템 버전 정보 추가
          rewardSystemVersion: "2.0",
          dailyRewardsEnabled: false,
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      // 7. 에스크로 거래 내역 생성
      const escrowTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(escrowTransactionRef, {
        userId: ESCROW_ACCOUNT_ID,
        type: "earn",
        amount: amount,
        status: "completed",
        description: `에스크로 예치 수령: ${appName} (공급자: ${providerName})`,
        metadata: {
          appId: appId,
          appName: appName,
          providerId: providerId,
          providerName: providerName,
          escrowType: "deposit",
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      // 8. escrow_holdings 문서 생성
      const holdingRef = getFirestore().collection("escrow_holdings").doc();
      transaction.set(holdingRef, {
        holdingId: holdingRef.id,
        appId: appId,
        appName: appName,
        providerId: providerId,
        providerName: providerName,
        totalAmount: amount,
        remainingAmount: amount,
        spentAmount: 0,
        status: "active",
        breakdown: {
          ...(breakdown || {}),
          // v2.112.0: 리워드 시스템 버전 정보
          rewardSystemVersion: "2.0",
          dailyRewardsEnabled: false,
        },
        transactions: [
          {
            type: "deposit",
            amount: amount,
            from: providerId,
            to: ESCROW_ACCOUNT_ID,
            description: "앱 등록 에스크로 예치",
            createdAt: FieldValue.serverTimestamp(),
          },
        ],
        depositedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✅ Escrow deposit successful - App: ${appId}, Amount: ${amount}`);

      return {
        success: true,
        holdingId: holdingRef.id,
        providerBalance: providerBalance - amount,
        escrowBalance: escrowBalance + amount,
      };
    });
  } catch (error) {
    console.error("❌ Escrow deposit failed:", error);
    // v2.102.1: HttpsError 타입 보존
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

/**
 * payoutFromEscrow - 미션 완료 시 에스크로에서 테스터에게 지급
 * @param {string} appId - 앱 ID
 * @param {string} testerId - 테스터 ID
 * @param {number} amount - 지급 금액
 * @param {string} description - 지급 사유
 */
exports.payoutFromEscrow = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {appId, testerId, testerName, amount, description, metadata} = request.data;
  const adminUid = request.auth?.uid;

  // 인증 확인
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 입력 검증
  if (!appId || !testerId || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid parameters");
  }

  // v2.102.1: 관리자 또는 공급자 권한 확인
  const isAdminUser = await isAdmin(adminUid);
  const isAppProvider = await isProjectProvider(adminUid, appId);

  if (!isAdminUser && !isAppProvider) {
    throw new HttpsError("permission-denied", "Only admin or app provider can authorize payouts");
  }

  try {
    return await getFirestore().runTransaction(async (transaction) => {
      // 1. escrow_holdings 조회
      const holdingsSnapshot = await getFirestore()
          .collection("escrow_holdings")
          .where("appId", "==", appId)
          .where("status", "==", "active")
          .limit(1)
          .get();

      // v2.166.0: 에러 메시지 상세화
      if (holdingsSnapshot.empty) {
        console.error(`❌ No active escrow holding found - appId: ${appId}`);
        throw new HttpsError(
            "not-found",
            `No active escrow holding found for appId: ${appId}. ` +
            `Please ensure the app is registered with escrow deposit.`,
        );
      }

      const holdingDoc = holdingsSnapshot.docs[0];
      const holdingRef = holdingDoc.ref;
      const holding = holdingDoc.data();

      // v2.112.0: 리워드 시스템 버전 체크 - 일일 포인트 지급 차단
      const rewardSystemVersion = holding.breakdown?.rewardSystemVersion || "1.0";
      const rewardType = metadata?.rewardType;

      if (rewardSystemVersion === "2.0") {
        // 신규 시스템: 최종 완료 포인트만 허용
        if (rewardType !== "final") {
          throw new HttpsError(
              "failed-precondition",
              "v2.112.0: Daily rewards are disabled. Only final completion rewards are allowed.",
          );
        }

        // 최종 완료 여부 확인
        if (!metadata?.allDaysCompleted) {
          throw new HttpsError(
              "failed-precondition",
              "Final reward can only be paid when all days are completed.",
          );
        }
      }

      // 2. 에스크로 잔액 확인
      if (holding.remainingAmount < amount) {
        throw new HttpsError("failed-precondition", `Insufficient escrow balance. Required: ${amount}, Available: ${holding.remainingAmount}`);
      }

      // 3. 에스크로 지갑 조회
      const escrowWalletRef = getFirestore().collection("wallets").doc(ESCROW_ACCOUNT_ID);
      const escrowWallet = await transaction.get(escrowWalletRef);

      // v2.166.0: SYSTEM_ESCROW 지갑 존재 여부 체크
      if (!escrowWallet.exists) {
        console.error(`❌ SYSTEM_ESCROW wallet not found - walletId: ${ESCROW_ACCOUNT_ID}`);
        throw new HttpsError(
            "not-found",
            `SYSTEM_ESCROW wallet not found. Please initialize the escrow wallet.`,
        );
      }

      const escrowBalance = escrowWallet.data().balance || 0;

      // 4. 테스터 지갑 조회
      const testerWalletRef = getFirestore().collection("wallets").doc(testerId);
      const testerWallet = await transaction.get(testerWalletRef);

      if (!testerWallet.exists) {
        throw new HttpsError("not-found", "Tester wallet not found");
      }

      const testerBalance = testerWallet.data().balance || 0;

      // 5. 에스크로 지갑 차감
      transaction.update(escrowWalletRef, {
        balance: escrowBalance - amount,
        totalSpent: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 6. 테스터 지갑 증가
      transaction.update(testerWalletRef, {
        balance: testerBalance + amount,
        totalEarned: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 7. escrow_holdings 업데이트
      const newTransactions = holding.transactions || [];
      newTransactions.push({
        type: "payout",
        amount: amount,
        from: ESCROW_ACCOUNT_ID,
        to: testerId,
        description: description || "미션 완료 보상",
        createdAt: FieldValue.serverTimestamp(),
      });

      transaction.update(holdingRef, {
        remainingAmount: holding.remainingAmount - amount,
        spentAmount: (holding.spentAmount || 0) + amount,
        transactions: newTransactions,
        lastPayoutAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 8. 에스크로 거래 내역 생성
      const escrowTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(escrowTransactionRef, {
        userId: ESCROW_ACCOUNT_ID,
        type: "spend",
        amount: amount,
        status: "completed",
        description: `에스크로 지급: ${description} (테스터: ${testerName})`,
        metadata: {
          appId: appId,
          testerId: testerId,
          testerName: testerName,
          escrowType: "payout",
          ...(metadata || {}),
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      // 9. 테스터 거래 내역 생성
      const testerTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(testerTransactionRef, {
        userId: testerId,
        type: "earn",
        amount: amount,
        status: "completed",
        description: description || "미션 완료 보상",
        metadata: {
          appId: appId,
          escrowType: "payout",
          ...(metadata || {}),
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✅ Escrow payout successful - App: ${appId}, Tester: ${testerId}, Amount: ${amount}`);

      return {
        success: true,
        testerBalance: testerBalance + amount,
        escrowBalance: escrowBalance - amount,
        remainingEscrow: holding.remainingAmount - amount,
      };
    });
  } catch (error) {
    console.error("❌ Escrow payout failed:", error);
    // v2.102.1: HttpsError 타입 보존
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

/**
 * refundEscrow - 앱 종료 시 잔액을 공급자에게 환불
 * @param {string} appId - 앱 ID
 */
exports.refundEscrow = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {appId} = request.data;
  const adminUid = request.auth?.uid;

  // 인증 확인
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 입력 검증
  if (!appId) {
    throw new HttpsError("invalid-argument", "App ID is required");
  }

  // v2.102.1: 관리자 또는 공급자 권한 확인
  const isAdminUser = await isAdmin(adminUid);
  const isAppProvider = await isProjectProvider(adminUid, appId);

  if (!isAdminUser && !isAppProvider) {
    throw new HttpsError("permission-denied", "Only admin or app provider can authorize refunds");
  }

  try {
    return await getFirestore().runTransaction(async (transaction) => {
      // 1. escrow_holdings 조회
      const holdingsSnapshot = await getFirestore()
          .collection("escrow_holdings")
          .where("appId", "==", appId)
          .where("status", "==", "active")
          .limit(1)
          .get();

      if (holdingsSnapshot.empty) {
        throw new HttpsError("not-found", "Active escrow holding not found for this app");
      }

      const holdingDoc = holdingsSnapshot.docs[0];
      const holdingRef = holdingDoc.ref;
      const holding = holdingDoc.data();
      const refundAmount = holding.remainingAmount;

      // 환불할 금액이 없으면 바로 완료 처리
      if (refundAmount <= 0) {
        transaction.update(holdingRef, {
          status: "completed",
          completedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        return {
          success: true,
          refundAmount: 0,
          message: "No amount to refund",
        };
      }

      // 2. 에스크로 지갑 조회
      const escrowWalletRef = getFirestore().collection("wallets").doc(ESCROW_ACCOUNT_ID);
      const escrowWallet = await transaction.get(escrowWalletRef);
      const escrowBalance = escrowWallet.data().balance || 0;

      // 3. 공급자 지갑 조회
      const providerWalletRef = getFirestore().collection("wallets").doc(holding.providerId);
      const providerWallet = await transaction.get(providerWalletRef);
      const providerBalance = providerWallet.data().balance || 0;

      // 4. 에스크로 지갑 차감
      transaction.update(escrowWalletRef, {
        balance: escrowBalance - refundAmount,
        totalSpent: FieldValue.increment(refundAmount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 5. 공급자 지갑 증가
      transaction.update(providerWalletRef, {
        balance: providerBalance + refundAmount,
        totalEarned: FieldValue.increment(refundAmount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 6. escrow_holdings 업데이트
      const newTransactions = holding.transactions || [];
      newTransactions.push({
        type: "refund",
        amount: refundAmount,
        from: ESCROW_ACCOUNT_ID,
        to: holding.providerId,
        description: "앱 종료로 인한 에스크로 환불",
        createdAt: FieldValue.serverTimestamp(),
      });

      transaction.update(holdingRef, {
        remainingAmount: 0,
        status: "refunded",
        transactions: newTransactions,
        refundedAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 7. 거래 내역 생성 (에스크로)
      const escrowTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(escrowTransactionRef, {
        userId: ESCROW_ACCOUNT_ID,
        type: "spend",
        amount: refundAmount,
        status: "completed",
        description: `에스크로 환불: ${holding.appName} (공급자: ${holding.providerName})`,
        metadata: {
          appId: appId,
          providerId: holding.providerId,
          escrowType: "refund",
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      // 8. 거래 내역 생성 (공급자)
      const providerTransactionRef = getFirestore().collection("transactions").doc();
      transaction.set(providerTransactionRef, {
        userId: holding.providerId,
        type: "refund",
        amount: refundAmount,
        status: "completed",
        description: `앱 종료 에스크로 환불: ${holding.appName}`,
        metadata: {
          appId: appId,
          escrowType: "refund",
        },
        createdAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✅ Escrow refund successful - App: ${appId}, Amount: ${refundAmount}`);

      return {
        success: true,
        refundAmount: refundAmount,
        providerBalance: providerBalance + refundAmount,
        escrowBalance: escrowBalance - refundAmount,
      };
    });
  } catch (error) {
    console.error("❌ Escrow refund failed:", error);
    // v2.102.1: HttpsError 타입 보존
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

/**
 * getEscrowBalance - 앱의 에스크로 잔액 조회
 * @param {string} appId - 앱 ID
 */
exports.getEscrowBalance = onCall({
  region: "asia-northeast1",
}, async (request) => {
  const {appId} = request.data;
  const uid = request.auth?.uid;

  // 인증 확인
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 입력 검증
  if (!appId) {
    throw new HttpsError("invalid-argument", "App ID is required");
  }

  try {
    const holdingsSnapshot = await getFirestore()
        .collection("escrow_holdings")
        .where("appId", "==", appId)
        .where("status", "==", "active")
        .limit(1)
        .get();

    if (holdingsSnapshot.empty) {
      return {
        success: true,
        found: false,
        message: "No active escrow holding found",
      };
    }

    const holding = holdingsSnapshot.docs[0].data();

    return {
      success: true,
      found: true,
      totalAmount: holding.totalAmount,
      remainingAmount: holding.remainingAmount,
      spentAmount: holding.spentAmount || 0,
      status: holding.status,
      breakdown: holding.breakdown || {},
    };
  } catch (error) {
    console.error("❌ Get escrow balance failed:", error);
    // v2.102.1: HttpsError 타입 보존
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

// ============================================================================
// v2.110.0: Project Deletion & Escrow Refund
// ============================================================================

/**
 * refundOnProjectDelete - 프로젝트 삭제 시 에스크로 자동 환불
 * Trigger: projects 문서 삭제 시 자동 실행
 *
 * 처리 흐름:
 * 1. 삭제된 프로젝트의 escrow_holdings 조회 (status='active')
 * 2. 트랜잭션으로 일괄 처리:
 *    - 공급자 지갑 잔액 복구
 *    - 에스크로 지갑 차감
 *    - escrow_holdings 상태 업데이트 (active → refunded)
 *    - transactions 기록 생성
 */
exports.refundOnProjectDelete = onDocumentDeleted({
  document: "projects/{projectId}",
  region: "asia-northeast1",
}, async (event) => {
  const projectId = event.params.projectId;
  const deletedProject = event.data.data(); // 삭제된 프로젝트 데이터
  const appName = deletedProject?.appName || deletedProject?.title || "Deleted App";

  console.log(`🔄 [Refund] Project deleted: ${projectId} (${appName})`);

  try {
    // 1. 에스크로 홀딩 조회 (status='active')
    const holdingsSnapshot = await getFirestore()
        .collection("escrow_holdings")
        .where("appId", "==", projectId)
        .where("status", "==", "active")
        .get();

    if (holdingsSnapshot.empty) {
      console.log(`ℹ️  [Refund] No active escrow holding for project ${projectId}`);
      return null;
    }

    console.log(`📦 [Refund] Found ${holdingsSnapshot.size} active holding(s) for project ${projectId}`);

    // 2. 트랜잭션으로 환불 처리
    return await getFirestore().runTransaction(async (transaction) => {
      let totalRefunded = 0;
      const refundResults = [];

      for (const holdingDoc of holdingsSnapshot.docs) {
        const holding = holdingDoc.data();
        const amount = holding.remainingAmount || holding.totalAmount || 0;
        const providerId = holding.providerId;
        const providerName = holding.providerName || "Unknown Provider";

        if (amount <= 0) {
          console.log(`⚠️  [Refund] Holding ${holdingDoc.id} has no remaining amount, skipping`);
          continue;
        }

        console.log(`💰 [Refund] Processing holding ${holdingDoc.id}: ${amount}P to provider ${providerId}`);

        // 2.1 공급자 지갑 조회 및 복구
        const providerWalletRef = getFirestore()
            .collection("wallets")
            .doc(providerId);
        const providerWallet = await transaction.get(providerWalletRef);

        if (providerWallet.exists) {
          transaction.update(providerWalletRef, {
            balance: FieldValue.increment(amount),
            updatedAt: FieldValue.serverTimestamp(),
          });
          console.log(`✅ [Refund] Provider wallet ${providerId} +${amount}P`);
        } else {
          console.warn(`⚠️  [Refund] Provider wallet ${providerId} not found, skipping wallet update`);
        }

        // 2.2 에스크로 지갑 차감
        const escrowWalletRef = getFirestore()
            .collection("wallets")
            .doc(ESCROW_ACCOUNT_ID);
        const escrowWallet = await transaction.get(escrowWalletRef);

        if (escrowWallet.exists) {
          transaction.update(escrowWalletRef, {
            balance: FieldValue.increment(-amount),
            updatedAt: FieldValue.serverTimestamp(),
          });
          console.log(`✅ [Refund] Escrow wallet -${amount}P`);
        }

        // 2.3 escrow_holdings 상태 업데이트
        transaction.update(holdingDoc.ref, {
          status: "refunded",
          refundedAt: FieldValue.serverTimestamp(),
          refundReason: "project_deleted",
          updatedAt: FieldValue.serverTimestamp(),
        });

        // 2.4 트랜잭션 기록 생성 (공급자)
        const providerTxRef = getFirestore().collection("transactions").doc();
        transaction.set(providerTxRef, {
          userId: providerId,
          type: "earn",
          amount: amount,
          status: "completed",
          description: `에스크로 환불: ${appName}`,
          metadata: {
            appId: projectId,
            appName: appName,
            originalHoldingId: holdingDoc.id,
            refundReason: "project_deleted",
            refundType: "escrow_refund",
          },
          createdAt: FieldValue.serverTimestamp(),
          completedAt: FieldValue.serverTimestamp(),
        });
        console.log(`✅ [Refund] Transaction record created for provider ${providerId}`);

        // 2.5 트랜잭션 기록 생성 (에스크로)
        const escrowTxRef = getFirestore().collection("transactions").doc();
        transaction.set(escrowTxRef, {
          userId: ESCROW_ACCOUNT_ID,
          type: "spend",
          amount: amount,
          status: "completed",
          description: `에스크로 환불: ${appName} (공급자: ${providerName})`,
          metadata: {
            appId: projectId,
            appName: appName,
            providerId: providerId,
            providerName: providerName,
            originalHoldingId: holdingDoc.id,
            refundReason: "project_deleted",
            refundType: "escrow_refund",
          },
          createdAt: FieldValue.serverTimestamp(),
          completedAt: FieldValue.serverTimestamp(),
        });

        totalRefunded += amount;
        refundResults.push({
          holdingId: holdingDoc.id,
          providerId: providerId,
          amount: amount,
        });
      }

      console.log(`✅ [Refund] Transaction completed - Total refunded: ${totalRefunded}P for ${refundResults.length} holding(s)`);

      return {
        success: true,
        projectId: projectId,
        appName: appName,
        totalRefunded: totalRefunded,
        holdingsCount: refundResults.length,
        refundResults: refundResults,
      };
    });
  } catch (error) {
    console.error(`❌ [Refund] Failed for project ${projectId}:`, error);
    // Firestore trigger는 에러를 throw해도 재시도하므로, 로그만 남김
    return {
      success: false,
      error: error.message,
      projectId: projectId,
    };
  }
});

// Import migration functions
const migration = require('./migration.js');
exports.migrateUserOnWrite = migration.migrateUserOnWrite;
exports.bulkMigrateUsers = migration.bulkMigrateUsers;
exports.checkMigrationStatus = migration.checkMigrationStatus;
exports.validateMigratedUsers = migration.validateMigratedUsers;