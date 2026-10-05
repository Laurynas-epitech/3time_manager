import { reactive, readonly } from "vue";
import api, { csrfStorage } from "./api";

const state = reactive({
  user: null,
  // true once we know whether a session exists (avoids redirect flicker)
  checked: false,
});

function setSession(data) {
  state.user = data.data;
  csrfStorage.set(data.csrf_token);
}

function clearSession() {
  state.user = null;
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
  try {
    await api.post("/auth/logout");
  } finally {
    clearSession();
  }
}

// Restores the session after a page reload (cookie + csrf in localStorage).
async function fetchMe() {
  if (!csrfStorage.get()) {
    state.checked = true;
    return null;
  }

  try {
    const { data } = await api.get("/auth/me");
    state.user = data.data;
  } catch {
    clearSession();
  } finally {
    state.checked = true;
  }

  return state.user;
}

// Keeps the stored user in sync after a profile edit.
function updateUser(user) {
  state.user = { ...state.user, ...user };
}

function hasRole(...roles) {
  return !!state.user && roles.includes(state.user.role);
}

export const auth = {
  state: readonly(state),
  login,
  register,
  logout,
  fetchMe,
  updateUser,
  clearSession,
  hasRole,
};

export default auth;
