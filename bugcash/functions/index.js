const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

/**
 * Helper Functions
 */

// Check if user is admin
async function isAdmin(uid) {
  if (!uid) return false;
  try {
    const userDoc = await getFirestore().collection("users").doc(uid).get();
    return userDoc.exists && userDoc.data().role === "admin";
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

// Import migration functions
const migration = require('./migration.js');
exports.migrateUserOnWrite = migration.migrateUserOnWrite;
exports.bulkMigrateUsers = migration.bulkMigrateUsers;
exports.checkMigrationStatus = migration.checkMigrationStatus;
exports.validateMigratedUsers = migration.validateMigratedUsers;