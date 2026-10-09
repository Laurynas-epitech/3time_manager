// Shared time helpers. Times are stored in UTC by the API and shown in the
// viewer's local time; every period (day, week) is computed in local time.

export const TARGETS = {
  dailyHours: 8,
  weeklyHours: 40,
};

const HOUR_MS = 60 * 60 * 1000;

const pad = (n) => String(n).padStart(2, "0");

// --- Duration formats ---

// "7h 46m": the format used for every duration in the app
export function formatHours(hours) {
  const minutes = Math.round(Math.max(hours, 0) * 60);
  return `${Math.floor(minutes / 60)}h ${pad(minutes % 60)}m`;
}

// "8:05": only for compact day columns
export function formatClockHours(hours) {
  const minutes = Math.round(Math.max(hours, 0) * 60);
  return `${Math.floor(minutes / 60)}:${pad(minutes % 60)}`;
}

// "6:44:18": live timers
export function formatTimer(ms) {
  const seconds = Math.floor(Math.max(ms, 0) / 1000);
  return `${Math.floor(seconds / 3600)}:${pad(Math.floor(seconds / 60) % 60)}:${pad(seconds % 60)}`;
}

// --- Date formats (locale-aware) ---

// "09:12"
export function formatTime(value) {
  return new Date(value).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" });
}

// "Fri 9 Oct"
export function formatShortDate(value) {
  return new Date(value).toLocaleDateString(undefined, {
    weekday: "short",
    day: "numeric",
    month: "short",
  });
}

// "9 Oct"
export function formatDayMonth(value) {
  return new Date(value).toLocaleDateString(undefined, { day: "numeric", month: "short" });
}

// --- Calendar helpers ---

// "YYYY-MM-DD" of a local date
export function toDateKey(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

// Local midnight of a "YYYY-MM-DD" string
export function fromDateKey(key) {
  const [year, month, day] = key.split("-").map(Number);
  return new Date(year, month - 1, day);
}

export function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function addDays(date, days) {
  const copy = new Date(date);
  copy.setDate(copy.getDate() + days);
  return copy;
}

// Monday of the week containing `date`
export function startOfWeek(date) {
  return addDays(startOfDay(date), -((date.getDay() + 6) % 7));
}

// The API filter format: "YYYY-MM-DD HH:mm:ss" in UTC
export function toApiDateTime(date) {
  return date.toISOString().slice(0, 19).replace("T", " ");
}

/**
 * Hours per local day between `from` (inclusive) and `to` (exclusive).
 * Sessions crossing midnight are split between the days they cover, and
 * the parts outside the period are ignored. `sessions` are {start, end}
 * values (an open session can pass `end: new Date()`).
 * Returns { "YYYY-MM-DD": hours }.
 */
export function hoursByDay(sessions, from, to) {
  const days = {};

  for (let day = startOfDay(from); day < to; day = addDays(day, 1)) {
    days[toDateKey(day)] = 0;
  }

  for (const session of sessions) {
    let start = new Date(Math.max(new Date(session.start), from));
    const end = new Date(Math.min(new Date(session.end), to));

    while (start < end) {
      const nextMidnight = addDays(startOfDay(start), 1);
      const partEnd = end < nextMidnight ? end : nextMidnight;
      const key = toDateKey(start);

      if (key in days) days[key] += (partEnd - start) / HOUR_MS;
      start = partEnd;
    }
  }

  return days;
}

export function durationHours(session) {
  return (new Date(session.end) - new Date(session.start)) / HOUR_MS;
}
