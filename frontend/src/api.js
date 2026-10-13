import axios from "axios";
import { collectPages } from "./services/pagination";

// Same-origin proxy keeps credentials on the page's HTTPS connection.
const baseURL =
  import.meta.env.VITE_API_URL ||
  "/api";

export const apiScope = baseURL;

const CSRF_KEY = "tm_csrf_token";

export const csrfStorage = {
  get: () => localStorage.getItem(CSRF_KEY),
  set: (token) => localStorage.setItem(CSRF_KEY, token),
  clear: () => localStorage.removeItem(CSRF_KEY),
};

const api = axios.create({
  baseURL,
  timeout: 10000,
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

export async function fetchAll(path, { params = {}, reversePages = false, check = () => {} } = {}) {
  const data = await collectPages(async paging => {
    check();
    const response = await api.get(path, { params: { ...params, ...paging } });
    check();
    return response.data.data;
  }, { reversePages });
  return { data: { data } };
}

export async function fetchTeams() {
  const response = await fetchAll('/teams');
  // Hydrate large teams sequentially to avoid a burst of member requests.
  for (const team of response.data.data) {
    if (team.members_has_more) {
      team.members = (await fetchAll(`/teams/${team.id}/members`)).data.data;
      team.members_has_more = false;
    }
  }
  return response;
}
