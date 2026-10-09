import { reactive, readonly } from "vue";
import api, { csrfStorage } from "./api";
import { demoUser } from "./demoUser";
import { readOfflineUser, saveOfflineUser, forgetOfflineUser, offlineSessionKey } from "./services/offlineSession";

const demoEnabled = import.meta.env.DEV;

function isDemo() {
  return demoEnabled && sessionStorage.getItem("time-manager-demo") === "true";
}

const state = reactive({
  user: null,
  // true once we know whether a session exists (avoids redirect flicker)
  checked: false,
  offline: false,
});

function setSession(data) {
  sessionStorage.removeItem("time-manager-demo");
  state.user = data.data;
  state.offline = false;
  state.checked = true;
  saveOfflineUser(state.user);
  csrfStorage.set(data.csrf_token);
}

function clearSession() {
  sessionStorage.removeItem("time-manager-demo");
  state.user = null;
  state.checked = true;
  state.offline = false;
  forgetOfflineUser();
  csrfStorage.clear();
}

async function login(email, password) {
  const { data } = await api.post("/auth/login", { email, password });
  setSession(data);
  return state.user;
}

async function register({ username, email, password }) {
  const { data } = await api.post("/auth/register", {
    user: { username, email, password },
  });
  setSession(data);
  return state.user;
}

async function logout() {
  if (isDemo()) {
    sessionStorage.removeItem("time-manager-demo");
    clearSession();
    return;
  }

  try {
    await api.post("/auth/logout");
  } catch (error) {
    // Offline logout removes local access; the next visit requires online login.
    if (error.response) throw error;
  } finally {
    clearSession();
  }
}

// Restores the session after a page reload (cookie + csrf in localStorage).
async function fetchMe() {
  if (isDemo()) {
    state.user = { ...demoUser };
    state.checked = true;
    return state.user;
  }
  if (!csrfStorage.get()) {
    state.checked = true;
    return null;
  }

  try {
    const { data } = await api.get("/auth/me");
    state.user = data.data;
    state.offline = false;
    saveOfflineUser(state.user);
  } catch (error) {
    if (!error.response) {
      state.user = readOfflineUser();
      state.offline = !!state.user;
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
  if (!isDemo()) saveOfflineUser(state.user);
}

function confirmSession(user) {
  state.user = user;
  state.offline = false;
  saveOfflineUser(user);
}

function hasRole(...roles) {
  return !!state.user && roles.includes(state.user.role);
}
function loginDemo() {
  if (!demoEnabled) return null;
  clearSession();
  state.user = { ...demoUser };
  state.checked = true;

  sessionStorage.setItem("time-manager-demo", "true");

  return state.user;
}
export const auth = {
  demoEnabled,
  isDemo,
  confirmSession,
  state: readonly(state),
  login,
  loginDemo,
  register,
  logout,
  fetchMe,
  updateUser,
  clearSession,
  hasRole,
};

export default auth;

// A logout/account switch in another tab must remove this tab's cached access.
window.addEventListener("storage", (event) => {
  if (event.key !== offlineSessionKey || isDemo()) return;
  const storedUser = readOfflineUser();
  if (!storedUser || (state.user && storedUser.id !== state.user.id)) {
    state.user = null;
    state.checked = false;
    window.location.reload();
  }
});
