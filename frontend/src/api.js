import axios from "axios";
import { isNative } from "./native";

// Same host as the page, port 4000. Works on localhost and on the server
// (57.130.61.152) without changing the code. Can be overridden with VITE_API_URL.
const baseURL =
  import.meta.env.VITE_API_URL ||
  `${window.location.protocol}//${window.location.hostname}:4000/api`;

const CSRF_KEY = "tm_csrf_token";

export const csrfStorage = {
  get: () => localStorage.getItem(CSRF_KEY),
  set: (token) => localStorage.setItem(CSRF_KEY, token),
  clear: () => localStorage.removeItem(CSRF_KEY),
};

// Android app only: the JWT is sent as "Authorization: Bearer", because the
// cookie is not reliable between the app's WebView and the API.
// In the browser the JWT stays in the HTTP-only cookie and this is never set.
const JWT_KEY = "tm_jwt";

export const tokenStorage = {
  get: () => (isNative ? localStorage.getItem(JWT_KEY) : null),
  set: (token) => {
    if (isNative && token) localStorage.setItem(JWT_KEY, token);
  },
  clear: () => localStorage.removeItem(JWT_KEY),
};

const api = axios.create({
  baseURL,
  // Sends the HTTP-only JWT cookie with every request.
  withCredentials: true,
  // Fail fast on a bad connection, so the offline mode kicks in.
  timeout: 8000,
  headers: { "Content-Type": "application/json" },
});

// The JWT is in a cookie JS can't read. The csrf token (returned at login)
// goes in a header; the backend checks it matches the one inside the JWT.
api.interceptors.request.use((config) => {
  const csrf = csrfStorage.get();

  if (csrf) {
    config.headers["X-CSRF-Token"] = csrf;
  }

  const jwt = tokenStorage.get();

  if (jwt) {
    config.headers.Authorization = `Bearer ${jwt}`;
  }

  return config;
});

let onUnauthorized = null;

export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler;
}

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const url = error.config?.url || "";
    const isAuthCall = url.startsWith("/auth/login") || url.startsWith("/auth/register");

    if (error.response?.status === 401 && !isAuthCall && onUnauthorized) {
      onUnauthorized();
    }

    return Promise.reject(error);
  }
);

// Turns a backend error into a readable message.
export function errorMessage(error, fallback = "Something went wrong.") {
  const errors = error?.response?.data?.errors;

  if (!errors) return fallback;
  if (errors.detail) return errors.detail;

  return Object.entries(errors)
    .map(([field, messages]) => `${field} ${[].concat(messages).join(", ")}`)
    .join(" · ");
}

export default api;
