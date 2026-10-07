import { Preferences } from "@capacitor/preferences";

// Key/value storage on the device (Android SharedPreferences in the app,
// localStorage in the browser). Values are stored as JSON.
const PREFIX = "tm:";

export async function load(key, fallback = null) {
  try {
    const { value } = await Preferences.get({ key: PREFIX + key });
    return value === null ? fallback : JSON.parse(value);
  } catch {
    return fallback;
  }
}

export async function save(key, value) {
  await Preferences.set({ key: PREFIX + key, value: JSON.stringify(value) });
}

export async function remove(key) {
  await Preferences.remove({ key: PREFIX + key });
}

// Removes every cached value (used on logout).
export async function clearAll() {
  const { keys } = await Preferences.keys();
  await Promise.all(
    keys.filter((k) => k.startsWith(PREFIX)).map((key) => Preferences.remove({ key }))
  );
}
