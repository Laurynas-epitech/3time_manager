import { openDB } from 'idb';

// Separate from real pendingActions: demo records must never be uploaded.
let database;
function getDatabase() {
  if (!import.meta.env.DEV) throw new Error('Demo attendance is development-only.');
  database ??= openDB('time-manager-demo', 1, {
    upgrade(db) {
      db.createObjectStore('users', { keyPath: 'userId' });
    },
  });
  return database;
}

export async function getDemoAttendance(userId) {
  const db = await getDatabase();
  return (await db.get('users', userId)) ?? {
    userId, clockIn: false, startDateTime: null, workingTimes: [],
  };
}

export async function toggleDemoClock(userId) {
  const db = await getDatabase();
  const tx = db.transaction('users', 'readwrite');
  const attendance = (await tx.store.get(userId)) ?? {
    userId, clockIn: false, startDateTime: null, workingTimes: [],
  };
  const time = new Date().toISOString();
  if (attendance.clockIn) {
    attendance.workingTimes.push({
      id: crypto.randomUUID(), user_id: userId,
      start: attendance.startDateTime, end: time,
    });
    attendance.startDateTime = null;
  } else {
    attendance.startDateTime = time;
  }
  attendance.clockIn = !attendance.clockIn;
  await tx.store.put(attendance);
  await tx.done;
  return attendance;
}
