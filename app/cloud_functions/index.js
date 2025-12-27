/**
 * Firebase Cloud Functions for Love to Learn Sign
 * 
 * These functions handle:
 * 1. Updating Custom Claims when user roles change
 * 2. Validating admin access
 * 3. Creating user profiles on registration
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function: updateUserRoles
 * Triggered when a user document in /users/{uid} is updated
 * Updates Firebase Custom Claims with the user's roles array
 */
exports.updateUserRoles = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.data();
    const oldData = change.before.data();
    
    const newRoles = newData.roles || [];
    const oldRoles = oldData.roles || [];
    
    // Only update if roles actually changed
    const rolesChanged = JSON.stringify(newRoles.sort()) !== JSON.stringify(oldRoles.sort());
    
    if (!rolesChanged) {
      console.log(`Roles unchanged for user ${userId}, skipping Custom Claims update`);
      return null;
    }
    
    try {
      // Update Custom Claims
      await admin.auth().setCustomUserClaims(userId, {
        roles: newRoles,
      });
      
      console.log(`Updated Custom Claims for user ${userId} with roles:`, newRoles);
      
      // Log the change
      await admin.firestore().collection('roleLogs').add({
        userId: userId,
        oldRoles: oldRoles,
        newRoles: newRoles,
        updatedBy: 'cloud-function',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (error) {
      console.error(`Error updating Custom Claims for user ${userId}:`, error);
      throw error;
    }
  });

/**
 * Cloud Function: validateAdminAccess
 * Callable function to validate if a user has admin role
 */
exports.validateAdminAccess = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const uid = context.auth.uid;
  
  try {
    // Get user's Custom Claims
    const user = await admin.auth().getUser(uid);
    const roles = user.customClaims?.roles || [];
    
    const isAdmin = roles.includes('admin');
    
    return {
      isAdmin: isAdmin,
      roles: roles,
    };
  } catch (error) {
    console.error('Error validating admin access:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error validating admin access'
    );
  }
});

/**
 * Cloud Function: onUserRegistration
 * Triggered when a new user signs up via Firebase Auth
 * Creates a user document in Firestore with pending status
 */
exports.onUserRegistration = functions.auth.user().onCreate(async (user) => {
  try {
    const userDoc = {
      email: user.email || '',
      displayName: user.displayName || user.email?.split('@')[0] || 'User',
      roles: [], // NO DEFAULT ROLE
      status: 'pending',
      approved: false,
      photoUrl: user.photoURL || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await admin.firestore().collection('users').doc(user.uid).set(userDoc);
    
    console.log(`Created user document for ${user.uid} with pending status`);
    
    return null;
  } catch (error) {
    console.error(`Error creating user document for ${user.uid}:`, error);
    throw error;
  }
});

