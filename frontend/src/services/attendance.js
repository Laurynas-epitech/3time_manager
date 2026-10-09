import { reactive, readonly, watch } from 'vue';
import { openDB } from 'idb';
import api, { apiScope, errorMessage } from '../api';
import auth from '../auth';

// A fresh namespace excludes legacy test actions with no verified account owner.
const dbPromise = openDB('time-manager-offline', 1, {
  upgrade(db) {
    db.createObjectStore('snapshots', { keyPath: 'key' });
    const actions = db.createObjectStore('actions', { keyPath: 'sequence', autoIncrement: true });
    actions.createIndex('owner', ['scope', 'ownerId']);
  },
});
const state = reactive({ online: navigator.onLine, offlineReady: false, pending: 0, syncing: false, completed: 0, total: 0, error: '', revision: 0 });
export const attendanceState = readonly(state);
export function markOfflineReady() { state.offlineReady = true; }
const mutexes = new Map();
const updates = typeof BroadcastChannel === 'function' ? new BroadcastChannel('tm-attendance-updates') : null;

async function withLock(ownerId, task) {
  const name = `tm-attendance:${apiScope}:${ownerId}`;
  if (navigator.locks) return navigator.locks.request(name, task);
  const previous = mutexes.get(name) ?? Promise.resolve();
  const next = previous.catch(() => {}).then(task);
  mutexes.set(name, next);
  try { return await next; } finally { if (mutexes.get(name) === next) mutexes.delete(name); }
}

function owner() {
  if (!auth.state.user || auth.isDemo()) throw new Error('Sign in to use attendance.');
  return auth.state.user.id;
}
function key(ownerId, userId) { return [apiScope, ownerId, userId]; }
async function pending(db, ownerId) {
  return db.getAllFromIndex('actions', 'owner', [apiScope, ownerId]);
}
function announce(broadcast = true) {
  state.revision++;
  if (broadcast) updates?.postMessage({ scope: apiScope });
}
if (updates) updates.onmessage = async event => {
  if (event.data?.scope !== apiScope || !auth.state.user || auth.isDemo()) return;
  try {
    const ownerId = auth.state.user.id;
    const actions = await pending(await dbPromise, ownerId);
    if (auth.state.user?.id !== ownerId) return;
    state.pending = actions.length;
    announce(false);
  } catch { state.error = 'Unable to refresh local attendance. Reload and try again.'; }
};
function rows(response) {
  const data = response.data.data ?? response.data;
  return Array.isArray(data) ? data : [];
}

async function refreshSnapshot(db, ownerId, userId) {
  const [clocks, times] = await Promise.all([
    api.get(`/clock/${userId}`), api.get(`/workingtime/${userId}`),
  ]);
  if (auth.state.user?.id !== ownerId || auth.isDemo()) throw new Error('Account changed.');
  const snapshot = { key: key(ownerId, userId), clocks: rows(clocks), workingTimes: rows(times) };
  await db.put('snapshots', snapshot);
  return snapshot;
}

function project(snapshot, actions) {
  const clocks = [...snapshot.clocks];
  const workingTimes = [...snapshot.workingTimes];
  for (const action of actions) {
    if (clocks.some(clock => clock.client_action_id === action.id)) continue;
    const previous = clocks.at(-1);
    if (!action.status && previous?.status) {
      workingTimes.push({ id: `pending-${action.id}`, start: previous.time, end: action.timestamp, pending: true });
    }
    clocks.push({ id: `pending-${action.id}`, client_action_id: action.id, time: action.timestamp, status: action.status });
  }
  const latest = clocks.at(-1);
  return { clockIn: !!latest?.status, startDateTime: latest?.status ? latest.time : null, workingTimes };
}

export async function getAttendance(userId, { refresh = true } = {}) {
  const ownerId = owner();
  return withLock(ownerId, async () => {
    if (auth.state.user?.id !== ownerId || auth.isDemo()) throw new Error('Account changed.');
    const db = await dbPromise;
    const actions = (await pending(db, ownerId)).filter(action => action.userId === userId);
    let snapshot = await db.get('snapshots', key(ownerId, userId));
    if (refresh && navigator.onLine && !actions.length) {
      try { snapshot = await refreshSnapshot(db, ownerId, userId); state.online = true; }
      catch (error) {
        if (error.response) throw error;
        state.online = false;
        if (!snapshot) throw new Error('Connect once to download your attendance before using it offline.');
      }
    }
    if (!snapshot) throw new Error('Connect once to download your attendance before using it offline.');
    if (auth.state.user?.id !== ownerId || auth.isDemo()) throw new Error('Account changed.');
    return project(snapshot, actions);
  });
}

export async function recordAttendance(userId, status) {
  const ownerId = owner();
  await withLock(ownerId, async () => {
    if (auth.state.user?.id !== ownerId || auth.isDemo()) throw new Error('Account changed.');
    const db = await dbPromise;
    let snapshot = await db.get('snapshots', key(ownerId, userId));
    if (!snapshot && navigator.onLine) snapshot = await refreshSnapshot(db, ownerId, userId);
    if (!snapshot) throw new Error('Connect once to download your attendance first.');
    if (!navigator.onLine && ownerId !== userId) throw new Error('Offline attendance is available for your own account only.');
    const actions = await pending(db, ownerId);
    const current = project(snapshot, actions.filter(action => action.userId === userId));
    if (status === current.clockIn) {
      announce();
      throw new Error('Attendance changed in another tab. Check the updated status and try again.');
    }
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    if (snapshot.clocks.at(-1)?.time > timestamp || actions.at(-1)?.timestamp > timestamp) {
      throw new Error('Your device clock is behind the last attendance event. Correct the device time before clocking.');
    }
    await db.add('actions', { scope: apiScope, ownerId, userId, id: crypto.randomUUID(), status, timestamp });
    state.pending = actions.length + 1;
    announce();
  });
  // Local persistence succeeds independently of network delivery.
  void synchronizeAttendance();
}

async function acknowledge(db, action, clock) {
  const tx = db.transaction(['snapshots', 'actions'], 'readwrite');
  const snapshot = await tx.objectStore('snapshots').get(key(action.ownerId, action.userId));
  if (snapshot && !snapshot.clocks.some(item => item.client_action_id === action.id)) {
    const previous = snapshot.clocks.at(-1);
    if (!clock.status && previous?.status) {
      snapshot.workingTimes.push({ id: `synced-${action.id}`, start: previous.time, end: clock.time });
    }
    snapshot.clocks.push(clock);
    await tx.objectStore('snapshots').put(snapshot);
  }
  await tx.objectStore('actions').delete(action.sequence);
  await tx.done;
}

let running;
let syncRequested = false;
export function synchronizeAttendance() {
  if (running) {
    syncRequested = true;
    return running;
  }
  running = synchronize().finally(() => {
    running = null;
    if (syncRequested) {
      syncRequested = false;
      queueMicrotask(() => { void synchronizeAttendance(); });
    }
  });
  return running;
}

async function synchronize() {
  if (!auth.state.user || auth.isDemo()) return;
  const ownerId = auth.state.user.id;
  try {
    await withLock(ownerId, async () => {
      const db = await dbPromise;
      const actions = await pending(db, ownerId);
      state.pending = actions.length;
      state.online = navigator.onLine;
      if (!navigator.onLine) return;
      if (auth.state.user?.id !== ownerId || auth.isDemo()) return;
      state.syncing = true;
      state.completed = 0;
      state.total = actions.length;
      state.error = '';
      const { data } = await api.get('/auth/me');
      if (data.data.id !== ownerId) {
        auth.clearSession();
        throw new Error('Sign in to the original account to synchronise its pending attendance.');
      }
      if (auth.state.user?.id !== ownerId || auth.isDemo()) return;
      auth.confirmSession(data.data);
      const targets = new Set([ownerId]);
      for (const action of actions) {
        if (auth.state.user?.id !== ownerId || auth.isDemo()) return;
        const response = await api.post(`/clock/${action.userId}`, {
          clock: { time: action.timestamp, status: action.status, client_action_id: action.id, client_owner_id: ownerId },
        });
        // An old backend lacking deduplication must not silently drain this queue.
        if (response.data.data?.client_action_id !== action.id) {
          throw new Error('The backend must be updated for safe attendance synchronisation. Your action remains saved.');
        }
        await acknowledge(db, action, response.data.data);
        targets.add(action.userId);
        if (auth.state.user?.id !== ownerId || auth.isDemo()) return;
        state.completed++;
        state.pending--;
        announce();
      }
      for (const userId of targets) await refreshSnapshot(db, ownerId, userId);
      state.online = true;
      announce();
    });
  } catch (error) {
    if (!error.response && error.isAxiosError) {
      state.online = false;
      state.error = 'Connection unavailable. Saved actions will retry automatically.';
    } else if (error.response?.status === 401) {
      state.error = 'Session expired. Sign in again; your pending attendance is saved.';
    } else if ([403, 422].includes(error.response?.status)) {
      state.error = `Synchronisation stopped: ${errorMessage(error, 'attendance conflicts with server data or permissions')}. Your pending actions are retained.`;
    } else {
      state.error = error.message || 'Synchronisation failed. Your pending actions are retained.';
    }
  } finally { state.syncing = false; }
}

let started = false;
export function startAttendanceSync() {
  if (started) return;
  started = true;
  const retry = () => { void synchronizeAttendance(); };
  window.addEventListener('online', retry);
  window.addEventListener('offline', () => { state.online = false; });
  window.addEventListener('focus', retry);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) retry(); });
  setInterval(retry, 30000);
  watch(() => auth.state.user?.id, () => {
    state.pending = 0;
    if (!auth.state.user || auth.isDemo()) return;
    state.error = '';
    // If the previous account is still finishing, start this account afterwards.
    void (running ?? Promise.resolve()).then(retry);
  }, { immediate: true });
}
