/*
  Offline mode.

  - Reads: every successful GET is cached on the device. When the network is
    down, the cached copy is returned instead.
  - Writes (clock in/out): saved in a local queue WITH their original time,
    then sent. If there is no network they stay queued and are sent
    automatically when the connection comes back. The backend stores the
    `time` from the body, so a clock-in done offline at 08:02 is recorded at
    08:02 even if it reaches the server at 08:40.
*/
import { ref, computed } from "vue";
import { Network } from "@capacitor/network";
import { App } from "@capacitor/app";

import api from "./api";
import { load, save, remove } from "./storage";

const QUEUE_KEY = "queue";

export const online = ref(navigator.onLine);
export const queue = ref([]);
export const syncing = ref(false);
export const lastSyncError = ref("");
export const pendingCount = computed(() => queue.value.length);

// A request that never got an answer from the server.
export function isNetworkError(error) {
  return !!error && !error.response;
}

/* ---------------- Cached reads ---------------- */

// GET with a device cache. Returns { data, fromCache }.
export async function cachedGet(url, config = {}) {
  const key = `cache:${url}:${JSON.stringify(config.params || {})}`;

  try {
    const response = await api.get(url, config);
    await save(key, response.data);
    return { data: response.data, fromCache: false };
  } catch (error) {
    if (isNetworkError(error)) {
      const cached = await load(key);
      if (cached !== null) return { data: cached, fromCache: true };
    }
    throw error;
  }
}

/* ---------------- Queued writes ---------------- */

async function persistQueue() {
  await save(QUEUE_KEY, queue.value);
}

function newId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

// Records a clock in/out now, sends it when possible.
export async function queueClock(userId, status, time = new Date().toISOString()) {
  const action = { id: newId(), type: "clock", userId, status, time };

  queue.value = [...queue.value, action];
  await persistQueue();

  // Fire and forget: the UI already shows the new state.
  flush();

  return action;
}

// Pending clock actions of one user (to compute the status offline).
export function pendingClocks(userId) {
  return queue.value.filter((a) => a.type === "clock" && a.userId === userId);
}

async function send(action) {
  if (action.type === "clock") {
    await api.post(`/clock/${action.userId}`, {
      clock: { time: action.time, status: action.status },
    });
  }
}

let flushing = null;
let rerun = false;

// Sends the queue in order. Stops at the first network error (still offline).
// If called again while a sync is running (e.g. the network came back during a
// request that was hanging), it runs once more when the current one ends.
export function flush() {
  if (flushing) {
    rerun = true;
    return flushing;
  }

  if (!online.value || !queue.value.length) return Promise.resolve();

  flushing = (async () => {
    if (!queue.value.length) return;

    syncing.value = true;
    lastSyncError.value = "";

    try {
      while (queue.value.length) {
        const action = queue.value[0];

        try {
          await send(action);
        } catch (error) {
          if (isNetworkError(error)) break; // still offline: retry later

          if (error.response?.status === 401) break; // logged out: keep for later

          // Rejected by the server (403, 422...): drop it so it can't block the queue.
          lastSyncError.value = `A ${action.status ? "clock-in" : "clock-out"} from ${new Date(
            action.time
          ).toLocaleString()} was rejected by the server.`;
        }

        queue.value = queue.value.slice(1);
        await persistQueue();
      }
    } finally {
      syncing.value = false;
      flushing = null;
      window.dispatchEvent(new CustomEvent("tm:synced"));

      if (rerun) {
        rerun = false;
        if (online.value && queue.value.length) flush();
      }
    }
  })();

  return flushing;
}

export async function clearQueue() {
  queue.value = [];
  await remove(QUEUE_KEY);
}

/* ---------------- Start-up ---------------- */

export async function initOffline() {
  queue.value = await load(QUEUE_KEY, []);

  try {
    const status = await Network.getStatus();
    online.value = status.connected;
  } catch {
    online.value = navigator.onLine;
  }

  // Back online -> sync automatically.
  Network.addListener("networkStatusChange", (status) => {
    const wasOffline = !online.value;
    online.value = status.connected;
    if (status.connected && wasOffline) flush();
  });

  // App brought back to the foreground -> try again.
  try {
    App.addListener("resume", () => flush());
  } catch {
    /* browser */
  }

  if (online.value) flush();
}
