import { Capacitor } from "@capacitor/core";
import { Haptics, ImpactStyle, NotificationType } from "@capacitor/haptics";
import { LocalNotifications } from "@capacitor/local-notifications";
import { StatusBar, Style } from "@capacitor/status-bar";
import { SplashScreen } from "@capacitor/splash-screen";

// True inside the Android app, false in a browser.
export const isNative = Capacitor.isNativePlatform();

const REMINDER_ID = 1;
const REMINDER_AFTER_HOURS = 8;

export async function initNative() {
  if (!isNative) return;

  try {
    await StatusBar.setStyle({ style: Style.Dark });
    await StatusBar.setBackgroundColor({ color: "#111827" });
  } catch {
    // Not available on every Android version: ignore.
  }

  await SplashScreen.hide();
}

// Short vibration feedback. Silently does nothing where unsupported.
export async function vibrate(kind = "light") {
  try {
    if (kind === "success") {
      await Haptics.notification({ type: NotificationType.Success });
    } else if (kind === "warning") {
      await Haptics.notification({ type: NotificationType.Warning });
    } else {
      await Haptics.impact({ style: ImpactStyle.Medium });
    }
  } catch {
    /* no haptics */
  }
}

// Reminder notification after 8 hours on duty (app only).
export async function scheduleClockOutReminder(clockInTime) {
  if (!isNative) return;

  try {
    const permission = await LocalNotifications.requestPermissions();
    if (permission.display !== "granted") return;

    const at = new Date(new Date(clockInTime).getTime() + REMINDER_AFTER_HOURS * 3600 * 1000);
    if (at <= new Date()) return;

    await LocalNotifications.cancel({ notifications: [{ id: REMINDER_ID }] });
    await LocalNotifications.schedule({
      notifications: [
        {
          id: REMINDER_ID,
          title: "Still working?",
          body: `You clocked in ${REMINDER_AFTER_HOURS} hours ago. Don't forget to clock out.`,
          schedule: { at },
        },
      ],
    });
  } catch (error) {
    console.warn("Reminder not scheduled:", error);
  }
}

export async function cancelClockOutReminder() {
  if (!isNative) return;

  try {
    await LocalNotifications.cancel({ notifications: [{ id: REMINDER_ID }] });
  } catch {
    /* nothing scheduled */
  }
}
