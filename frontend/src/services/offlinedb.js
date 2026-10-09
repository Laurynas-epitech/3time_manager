import { openDB } from 'idb'

export const dbPromise = openDB('time-manager', 1, {
  upgrade(db) {
    if (!db.objectStoreNames.contains('attendance')) {
      db.createObjectStore('attendance', {
        keyPath: 'id'
      })
    }

    if (!db.objectStoreNames.contains('pendingActions')) {
      db.createObjectStore('pendingActions', {
        keyPath: 'id'
      })
    }
  }
})

export async function saveAttendance(record) {
  const db = await dbPromise
  await db.put('attendance', record)
}

export async function getAttendance() {
  const db = await dbPromise
  return db.getAll('attendance')
}