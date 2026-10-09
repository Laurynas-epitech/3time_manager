import { dbPromise } from './offlinedb'

// Save clock-in or clock-out locally
export async function queueClockAction(userId, status) {
  const db = await dbPromise

  const action = {
    id: crypto.randomUUID(),
    userId: userId,
    status: status,
    timestamp: new Date().toISOString(),
    synced: false
  }

  await db.put('pendingActions', action)

  console.log('Action saved locally:', action)

  return action
}

// Read all locally saved actions
export async function getPendingActions() {
  const db = await dbPromise
  return db.getAll('pendingActions')
}