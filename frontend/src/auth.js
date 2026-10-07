import { reactive, readonly } from "vue";
import api, { csrfStorage, tokenStorage } from "./api";
import { isNative } from "./native";
import { load, save, remove, clearAll } from "./storage";
import { flush, clearQueue, isNetworkError, pendingCount } from "./offline";

const state = reactive({
  user: null,
  // true once we know whether a session exists (avoids redirect flicker)
  checked: false,
  // true when the session was restored from the device without the server
  offlineSession: false,
});

async function setSession(data) {
  state.user = data.data;
  state.offlineSession = false;
  csrfStorage.set(data.csrf_token);
  tokenStorage.set(data.token);
  await save("user", data.data);
  flush();
}

// Forgets who is logged in, but keeps unsynced actions on the device:
// they are sent after the next login.
function clearSession() {
  state.user = null;
  state.offlineSession = false;
  csrfStorage.clear();
  tokenStorage.clear();
  remove("user");
}

async function login(email, password) {
  // The app asks for the JWT in the body (sent back as a bearer token).
  const { data } = await api.post("/auth/login", { email, password, mobile: isNative });
  await setSession(data);
  return state.user;
}

async function register({ username, email, password }) {
  const { data } = await api.post("/auth/register", {
    user: { username, email, password },
    mobile: isNative,
  });
  await setSession(data);
  return state.user;
}

// Full logout: also deletes the cached data and the unsynced queue.
async function logout() {
  try {
    await api.post("/auth/logout");
  } catch {
    // Offline: the cookie/token is forgotten locally anyway.
  }

  clearSession();
  await clearQueue();
  await clearAll();
}

// Warns before throwing away clock actions that never reached the server.
async function logoutWithConfirm() {
  if (pendingCount.value > 0) {
    await flush();
  }

  if (pendingCount.value > 0) {
    const n = pendingCount.value;
    const ok = window.confirm(
      `${n} clock action${n > 1 ? "s have" : " has"} not been synced yet. ` +
        "If you log out now, they will be lost. Log out anyway?"
    );
    if (!ok) return false;
  }

  await logout();
  return true;
}

// Restores the session after a reload / app restart.
// Offline: trust the user saved on the device until the server is reachable.
async function fetchMe() {
  if (!csrfStorage.get()) {
    state.checked = true;
    return null;
  }

  try {
    const { data } = await api.get("/auth/me");
    state.user = data.data;
    state.offlineSession = false;
    await save("user", data.data);
  } catch (error) {
    const saved = isNetworkError(error) ? await load("user") : null;

    if (saved) {
      state.user = saved;
      state.offlineSession = true;
    } else {
      clearSession();
    }
  } finally {
    state.checked = true;
  }

  return state.user;
}

// Keeps the stored user in sync after a profile edit.
function updateUser(user) {
  state.user = { ...state.user, ...user };
  save("user", state.user);
}

function hasRole(...roles) {
  return !!state.user && roles.includes(state.user.role);
}

export const auth = {
  state: readonly(state),
  login,
  register,
  logout,
  logoutWithConfirm,
  fetchMe,
  updateUser,
  clearSession,
  hasRole,
};

export default auth;
