// backfill_addedAt.js
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

(async () => {
  const snapshot = await db.collection('bangla_dictionary_eng_bnsl')
    .where('addedAt', '==', null)   // only documents missing addedAt
    .get();

  if (snapshot.empty) {
    console.log('All documents already have addedAt.');
    return;
  }

  console.log('Backfilling ' + snapshot.size + ' documents...');
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, { addedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();
  console.log('Backfill complete.');
  process.exit(0);
})();
