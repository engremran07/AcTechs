const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const {
  getFirestore,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  writeBatch,
  Timestamp,
} = require('firebase/firestore');

const firebaseConfig = {
  apiKey: 'AIzaSyDETPeEA7INduyW_3mo7pvCJ7QOPaaGrWw',
  authDomain: 'actechs-d415e.firebaseapp.com',
  projectId: 'actechs-d415e',
  storageBucket: 'actechs-d415e.firebasestorage.app',
  messagingSenderId: '493110256900',
  appId: '1:493110256900:web:8aa96a3450fad9c1569c51',
};

const USER_EMAIL = process.env.ACTECHS_USER_EMAIL || 'engremran89@gmail.com';
const USER_PASSWORD = process.env.ACTECHS_USER_PASSWORD || 'Aa100100a';

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const DAY_MS = 24 * 60 * 60 * 1000;
const daysAgo = (n) => Timestamp.fromDate(new Date(Date.now() - n * DAY_MS));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

const earningCats = [
  'Installed Bracket',
  'Installed Extra Pipe',
  'Old AC Removal',
  'Old AC Installation',
  'Sold Old AC',
  'Sold Scrap',
  'Other',
];

const workCats = [
  'Food',
  'Petrol',
  'Pipes',
  'Tools',
  'Tape',
  'Insulation',
  'Gas',
  'Other Consumables',
  'Other',
];

const homeCats = [
  'Bread/Roti',
  'Meat',
  'Tea',
  'Sugar',
  'Rice',
  'Vegetables',
  'Cooking Oil',
  'Milk',
  'Other Groceries',
];

async function clearOwnDocs(collectionName, uid) {
  const snap = await getDocs(
    query(collection(db, collectionName), where('techId', '==', uid)),
  );
  if (snap.empty) return 0;

  let batch = writeBatch(db);
  let count = 0;
  for (const row of snap.docs) {
    batch.delete(row.ref);
    count++;
    if (count % 350 === 0) {
      await batch.commit();
      batch = writeBatch(db);
    }
  }
  await batch.commit();
  return count;
}

async function main() {
  const cred = await signInWithEmailAndPassword(auth, USER_EMAIL, USER_PASSWORD);
  const uid = cred.user.uid;

  const userSnap = await getDoc(doc(db, 'users', uid));
  const userData = userSnap.exists() ? userSnap.data() : {};
  const techName = userData.name || cred.user.displayName || 'Technician';

  const deletedEarnings = await clearOwnDocs('earnings', uid);
  const deletedExpenses = await clearOwnDocs('expenses', uid);

  let batch = writeBatch(db);
  let opCount = 0;
  const flush = async () => {
    if (opCount >= 350) {
      await batch.commit();
      batch = writeBatch(db);
      opCount = 0;
    }
  };

  for (let i = 0; i < 40; i++) {
    batch.set(doc(collection(db, 'earnings')), {
      techId: uid,
      techName,
      category: pick(earningCats),
      amount: rand(100, 2500),
      note: pick(['', 'cash payment', 'bank transfer', 'نقد', 'آج کی سیل', 'تحويل']),
      date: daysAgo(rand(0, 45)),
      createdAt: daysAgo(rand(0, 45)),
    });
    opCount++;
    await flush();
  }

  for (let i = 0; i < 26; i++) {
    batch.set(doc(collection(db, 'expenses')), {
      techId: uid,
      techName,
      category: pick(workCats),
      amount: rand(20, 900),
      note: pick(['', 'site materials', 'diesel', 'موقع خرچہ', 'ورک']),
      expenseType: 'work',
      date: daysAgo(rand(0, 45)),
      createdAt: daysAgo(rand(0, 45)),
    });
    opCount++;
    await flush();
  }

  for (let i = 0; i < 18; i++) {
    batch.set(doc(collection(db, 'expenses')), {
      techId: uid,
      techName,
      category: pick(homeCats),
      amount: rand(10, 300),
      note: pick(['', 'family', 'گھر', 'منزل']),
      expenseType: 'home',
      date: daysAgo(rand(0, 45)),
      createdAt: daysAgo(rand(0, 45)),
    });
    opCount++;
    await flush();
  }

  await batch.commit();

  console.log(`Signed in as ${USER_EMAIL}`);
  console.log(`Cleared own docs -> earnings: ${deletedEarnings}, expenses: ${deletedExpenses}`);
  console.log('Seeded own In/Out docs -> earnings: 40, work expenses: 26, home expenses: 18');
}

main().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
