import { apiScope } from '../api';

export const offlineSessionKey = `tm_offline_user:${apiScope}`;
const key = offlineSessionKey;

export function readOfflineUser() {
  try {
    const user = JSON.parse(localStorage.getItem(key));
    return Number.isInteger(user?.id) && user.id > 0 ? user : null;
  } catch { return null; }
}

export function saveOfflineUser(user) {
  // Only the profile is cached. Passwords and JWT cookies are never copied here.
  localStorage.setItem(key, JSON.stringify(user));
}

export function forgetOfflineUser() {
  localStorage.removeItem(key);
}
