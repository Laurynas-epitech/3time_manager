import axios from "axios";

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

const api = axios.create({
  baseURL,
  // Sends the HTTP-only JWT cookie with every request.
  withCredentials: true,
  headers: { "Content-Type": "application/json" },
});

// The JWT is in a cookie JS can't read. The csrf token (returned at login)
// goes in a header; the backend checks it matches the one inside the JWT.
api.interceptors.request.use((config) => {
  const csrf = csrfStorage.get();

  if (csrf) {
    config.headers["X-CSRF-Token"] = csrf;
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
