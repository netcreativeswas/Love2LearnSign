/**
 * Script to set Custom Claims for admin users
 * Run this script to ensure all admin users have Custom Claims set
 * 
 * Usage: node set_admin_claims.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // You need to download this from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setAdminClaims() {
  try {
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    
    console.log(`Found ${usersSnapshot.size} users in Firestore`);
    
    let updatedCount = 0;
    let errorCount = 0;
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const roles = userData.roles || [];
      const uid = userData.uid; // Get UID from document data
      
      if (!uid) {
        console.log(`⚠️  Skipping ${doc.id}: No UID field found`);
        continue;
      }
      
      // Only process admin users
      if (roles.includes('admin')) {
        try {
          // Set Custom Claims
          await auth.setCustomUserClaims(uid, {
            roles: roles
          });
          
          console.log(`✅ Updated Custom Claims for ${userData.displayName || doc.id} (${uid}):`, roles);
          updatedCount++;
        } catch (error) {
          console.error(`❌ Error updating Custom Claims for ${uid}:`, error.message);
          errorCount++;
        }
      }
    }
    
    console.log(`\n📊 Summary:`);
    console.log(`   ✅ Updated: ${updatedCount}`);
    console.log(`   ❌ Errors: ${errorCount}`);
    console.log(`\n✨ Done! Admin users should now have Custom Claims set.`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  }
}

setAdminClaims();

