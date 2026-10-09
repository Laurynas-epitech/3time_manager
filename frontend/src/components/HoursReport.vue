<template>
  <section
    class="tm-card hours-report"
    aria-labelledby="hours-report-title"
  >
    <div class="report-head">
      <h2
        id="hours-report-title"
        class="tm-h2"
      >
        {{ title }}
      </h2>

      <RangeChips
        v-model="range"
        :options="ranges"
        label="Period"
      />
    </div>

    <!-- "Pick dates" -->
    <form
      v-if="range === 'pick'"
      class="pick-dates"
      @submit.prevent="load"
    >
      <label
        class="tm-label"
        for="report-from"
      >
        From
        <input
          id="report-from"
          v-model="from"
          class="tm-input"
          type="date"
          required
        />
      </label>

      <label
        class="tm-label"
        for="report-to"
      >
        To
        <input
          id="report-to"
          v-model="to"
          class="tm-input"
          type="date"
          required
        />
      </label>

      <button
        type="submit"
        class="tm-btn tm-btn--dark"
      >
        Show
      </button>
    </form>

    <p
      v-if="error"
      class="error-msg"
      role="alert"
    >
      {{ error }}
    </p>

    <template v-else>
      <div class="stats">
        <StatTile
          label="Total"
          :value="formatHours(totalHours)"
          tone="accent"
        />
        <StatTile
          label="Per week"
          :value="formatHours(perWeek)"
          tone="primary"
        />
        <StatTile
          label="Per worked day"
          :value="formatHours(perWorkedDay)"
        />
        <StatTile
          label="Days worked"
          :value="`${daysWorked} of ${days.length}`"
        />
      </div>

      <div
        v-if="loading"
        class="skeleton chart-skeleton"
        aria-hidden="true"
      ></div>

      <!-- One bar per day, or per week for periods longer than 14 days -->
      <div
        v-else
        class="bars"
        :class="{ dense: buckets.length > 14 }"
        :style="{ '--count': buckets.length }"
        role="img"
        :aria-label="`${bucketWord} hours from ${from} to ${to}. Details in the table below.`"
      >
        <div
          v-for="bucket in buckets"
          :key="bucket.key"
          class="bar-col"
          :title="`${bucket.label}: ${formatHours(bucket.hours)}`"
        >
          <span class="bar-value tm-num">{{ formatHours(bucket.hours) }}</span>
          <div
            class="bar"
            :class="{ current: bucket.current, empty: bucket.hours === 0 }"
            :style="{ height: `${barHeight(bucket.hours)}px` }"
          ></div>
          <span
            class="bar-label"
            :class="{ current: bucket.current }"
          >
            {{ bucket.label }}
          </span>
        </div>
      </div>

      <!-- Same numbers for screen readers and keyboard users -->
      <details class="report-table">
        <summary>Show as table</summary>

        <table class="data">
          <caption>{{ bucketWord }} hours from {{ from }} to {{ to }}</caption>
          <thead>
            <tr>
              <th scope="col">{{ grouping === "daily" ? "Day" : "Week" }}</th>
              <th scope="col">Hours</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="bucket in buckets"
              :key="bucket.key"
            >
              <td>{{ bucket.label }}</td>
              <td>{{ formatHours(bucket.hours) }}</td>
            </tr>
          </tbody>
        </table>
      </details>
    </template>
  </section>
</template>

<script>
import { errorMessage } from "../api";
import auth from "../auth";
import { getAttendance, attendanceState } from "../services/attendance";
import { getDemoAttendance } from "../services/demoAttendance";
import RangeChips from "./RangeChips.vue";
import StatTile from "./StatTile.vue";
import {
  addDays,
  formatDayMonth,
  formatHours,
  fromDateKey,
  hoursByDay,
  startOfDay,
  startOfWeek,
  toDateKey,
} from "../time";

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_DAYS = 366;
// Tallest bar in px (the chart area is 240px including value and date labels)
const BAR_MAX_PX = 170;

export default {
  name: "HoursReport",

  components: { RangeChips, StatTile },

  props: {
    userId: {
      type: Number,
      required: true,
    },

    title: {
      type: String,
      default: "How the weeks add up",
    },
  },

  data() {
    return {
      range: "last-4-weeks",
      ranges: [
        { id: "this-week", label: "This week" },
        { id: "last-4-weeks", label: "Last 4 weeks" },
        { id: "this-month", label: "This month" },
        { id: "pick", label: "Pick dates" },
      ],
      from: "",
      to: "",
      workingTimes: [],
      loading: false,
      error: "",
    };
  },

  computed: {
    attendanceRevision() { return attendanceState.revision; },
    periodStart() {
      return fromDateKey(this.from);
    },

    // Exclusive end: midnight after the "to" day
    periodEnd() {
      return addDays(fromDateKey(this.to), 1);
    },

    periodDays() {
      return (this.periodEnd - this.periodStart) / DAY_MS;
    },

    // [{ key, date, hours }] for every day of the period
    days() {
      if (!(this.periodDays > 0 && this.periodDays <= MAX_DAYS)) return [];

      const hours = hoursByDay(this.workingTimes, this.periodStart, this.periodEnd);
      return Object.entries(hours).map(([key, value]) => ({ key, date: fromDateKey(key), hours: value }));
    },

    grouping() {
      return this.days.length > 14 ? "weekly" : "daily";
    },

    bucketWord() {
      return this.grouping === "daily" ? "Daily" : "Weekly";
    },

    buckets() {
      const todayKey = toDateKey(new Date());

      if (this.grouping === "daily") {
        return this.days.map((day) => ({
          key: day.key,
          label: day.date.toLocaleDateString(undefined, { weekday: "short", day: "numeric" }),
          hours: day.hours,
          current: day.key === todayKey,
        }));
      }

      // Monday-based weeks, clipped to the period ("5–9 Oct")
      const currentWeek = toDateKey(startOfWeek(new Date()));
      const weeks = [];

      for (const day of this.days) {
        const key = toDateKey(startOfWeek(day.date));
        let week = weeks[weeks.length - 1];

        if (!week || week.key !== key) {
          week = { key, first: day.date, last: day.date, hours: 0, current: key === currentWeek };
          weeks.push(week);
        }

        week.last = day.date;
        week.hours += day.hours;
      }

      return weeks.map((week) => ({ ...week, label: this.weekLabel(week.first, week.last) }));
    },

    totalHours() {
      return this.days.reduce((sum, day) => sum + day.hours, 0);
    },

    daysWorked() {
      return this.days.filter((day) => day.hours > 0).length;
    },

    perWeek() {
      return this.days.length ? (this.totalHours / this.days.length) * 7 : 0;
    },

    perWorkedDay() {
      return this.daysWorked ? this.totalHours / this.daysWorked : 0;
    },

    maxBucket() {
      return Math.max(...this.buckets.map((bucket) => bucket.hours), 0);
    },
  },

  watch: {
    attendanceRevision() { if (!auth.isDemo()) this.load(false); },
    userId() {
      this.load();
    },

    range(id) {
      if (id !== "pick") this.applyRange(id);
    },
  },

  created() {
    this.applyRange(this.range);
  },

  methods: {
    formatHours,

    applyRange(id) {
      const today = startOfDay(new Date());

      const starts = {
        "this-week": startOfWeek(today),
        "last-4-weeks": addDays(startOfWeek(today), -21),
        "this-month": new Date(today.getFullYear(), today.getMonth(), 1),
      };

      this.from = toDateKey(starts[id]);
      this.to = toDateKey(today);
      this.load();
    },

    async load(refresh = true) {
      this.error = "";

      if (!this.userId || !this.from || !this.to) return;

      if (this.periodStart > fromDateKey(this.to)) {
        this.error = "The start date must be before the end date.";
        return;
      }

      if (this.periodDays > MAX_DAYS) {
        this.error = `Please choose a period of at most ${MAX_DAYS} days.`;
        return;
      }

      this.loading = true;

      try {
        const attendance = auth.isDemo()
          ? await getDemoAttendance(this.userId)
          : await getAttendance(this.userId, { refresh: refresh !== false });
        this.workingTimes = attendance.workingTimes;
      } catch (error) {
        this.workingTimes = [];
        this.error = errorMessage(error, "Could not load the working hours.");
      } finally {
        this.loading = false;
      }
    },

    barHeight(hours) {
      return this.maxBucket ? Math.max((hours / this.maxBucket) * BAR_MAX_PX, 2) : 2;
    },

    weekLabel(first, last) {
      if (toDateKey(first) === toDateKey(last)) return formatDayMonth(first);

      return first.getMonth() === last.getMonth()
        ? `${first.getDate()}–${formatDayMonth(last)}`
        : `${formatDayMonth(first)}–${formatDayMonth(last)}`;
    },
  },
};
</script>

<style scoped>
.hours-report {
  display: flex;
  flex-direction: column;
  gap: 22px;
}

.report-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: var(--tm-gap);
}

.pick-dates {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: var(--tm-gap);
}

.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(200px, 100%), 1fr));
  gap: var(--tm-gap);
}

.bars {
  display: grid;
  grid-template-columns: repeat(var(--count), minmax(0, 1fr));
  gap: var(--tm-gap);
  align-items: end;
  height: 240px;
  padding-top: 8px;
}

.bars.dense {
  gap: 4px;
}

/* value label sits right on top of its bar */
.bar-col {
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  height: 100%;
  min-width: 0;
  gap: 6px;
}

.bar-value {
  text-align: center;
  font-weight: 700;
  font-size: 15px;
  white-space: nowrap;
}

.bar {
  flex-shrink: 0;
  border: var(--tm-border);
  border-radius: 14px 14px 4px 4px;
  background: var(--tm-primary);
}

.bar.current {
  background: var(--tm-accent);
}

.bar.empty {
  border-style: dashed;
  border-color: var(--tm-line-dashed);
  background: transparent;
}

.bar-label {
  text-align: center;
  font-size: 14px;
  font-weight: 600;
  color: var(--tm-ink-muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.bar-label.current {
  color: var(--tm-accent-strong);
}

/* Many bars: hide per-bar values, they are in the tooltip and the table */
.bars.dense .bar-value {
  visibility: hidden;
}

.bars.dense .bar {
  border-radius: 8px 8px 3px 3px;
}

.bars.dense .bar-label {
  font-size: 11px;
}

.chart-skeleton {
  height: 240px;
}

.report-table summary {
  cursor: pointer;
  font-weight: 700;
  color: var(--tm-primary-text);
  min-height: var(--tm-hit);
  display: flex;
  align-items: center;
}

.report-table caption {
  text-align: left;
  color: var(--tm-ink-muted);
  padding-bottom: 6px;
}

@media (max-width: 640px) {
  .stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .stats :deep(.tm-stat__value) {
    font-size: 24px;
  }

  .bar-value {
    font-size: 12px;
  }

  .bars {
    gap: 6px;
  }
}
</style>
