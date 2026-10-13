import { fromDateKey, toDateKey, addDays, startOfWeek, hoursByDay } from '../time.js';

export function reportBuckets(sessions, from, to) {
  const valid = key => /^\d{4}-\d{2}-\d{2}$/.test(key) && toDateKey(fromDateKey(key)) === key;
  if (!valid(from) || !valid(to) || from > to) throw new Error('Choose valid dates in order.');
  const start = fromDateKey(from), end = addDays(fromDateKey(to), 1);
  const count = (Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86400000 + 1;
  if (count > 366) throw new Error('Choose at most 366 days.');
  const daily = Object.entries(hoursByDay(sessions, start, end)).map(([label, hours]) => ({ label, hours }));
  const weekly = [], weekday = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'].map(label => ({ label, hours: 0 }));
  for (const day of daily) {
    const date = fromDateKey(day.label), key = toDateKey(startOfWeek(date));
    let week = weekly.at(-1);
    if (!week || week.key !== key) { week = { key, first: day.label, last: day.label, hours: 0, count: 0 }; weekly.push(week); }
    week.last = day.label; week.hours += day.hours; week.count++;
    weekday[(date.getDay() + 6) % 7].hours += day.hours;
  }
  return { daily, weekly: weekly.map(week => ({ ...week, label: `${week.first} – ${week.last}${week.count < 7 ? ' (partial week)' : ''}` })), weekday };
}
