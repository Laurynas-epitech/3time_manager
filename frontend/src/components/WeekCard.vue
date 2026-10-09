<template>
  <section
    class="tm-card week-card"
    :aria-labelledby="headingId"
  >
    <div class="week-head">
      <div>
        <h2
          :id="headingId"
          class="tm-h2"
        >
          {{ title }}
        </h2>
        <p
          v-if="subtitle"
          class="subtitle"
        >
          {{ subtitle }}
        </p>
      </div>

      <!-- The "aside" slot (e.g. a live timer) takes the total's place; the total moves to the footer -->
      <slot name="aside">
        <div class="week-total">
          <strong class="tm-num">{{ formatHours(totalHours) }}</strong>
          <span> / {{ TARGETS.weeklyHours }}h</span>
        </div>
      </slot>
    </div>

    <ol class="days">
      <li
        v-for="day in days"
        :key="day.key"
        class="day"
        :class="day.state"
        :aria-label="`${day.longLabel}: ${day.state === 'future' ? 'upcoming' : formatHours(day.hours)}`"
      >
        <span
          class="day-name"
          aria-hidden="true"
        >
          {{ day.name }}
        </span>

        <div
          class="day-box"
          aria-hidden="true"
        >
          <div
            v-if="day.state !== 'future'"
            class="day-fill"
            :class="{ live: day.live }"
            :style="{ height: `${day.fill}%` }"
          ></div>
        </div>

        <span
          class="day-hours tm-num"
          aria-hidden="true"
        >
          {{ day.state === "future" ? "—" : formatClockHours(day.hours) }}
        </span>
      </li>
    </ol>

    <p
      v-if="$slots.aside"
      class="week-footer"
    >
      <strong class="tm-num">{{ formatHours(totalHours) }}</strong>
      of {{ TARGETS.weeklyHours }}h ·
      {{ remainingHours > 0 ? `${formatHours(remainingHours)} to go` : "target reached" }}
    </p>
  </section>
</template>

<script>
import {
  TARGETS,
  addDays,
  formatClockHours,
  formatHours,
  hoursByDay,
  startOfDay,
  startOfWeek,
  toDateKey,
} from "../time";

let uid = 0;

export default {
  name: "WeekCard",

  props: {
    title: {
      type: String,
      default: "This week's card",
    },

    subtitle: {
      type: String,
      default: "",
    },

    workingTimes: {
      type: Array,
      default: () => [],
    },

    // Start of the running session, if the person is clocked in
    liveSince: {
      type: [String, Date],
      default: null,
    },
  },

  data() {
    return {
      TARGETS,
      now: Date.now(),
      ticker: null,
      headingId: `week-card-${++uid}`,
    };
  },

  computed: {
    days() {
      const today = startOfDay(new Date(this.now));
      const monday = startOfWeek(today);
      const sessions = [...this.workingTimes];

      if (this.liveSince) sessions.push({ start: this.liveSince, end: new Date(this.now) });

      const hours = hoursByDay(sessions, monday, addDays(monday, 7));

      return Array.from({ length: 7 }, (_, i) => {
        const date = addDays(monday, i);
        const key = toDateKey(date);
        const state = date < today ? "past" : date > today ? "future" : "today";

        return {
          key,
          state,
          hours: hours[key],
          live: state === "today" && !!this.liveSince,
          fill: Math.min((hours[key] / TARGETS.dailyHours) * 100, 100),
          name: date.toLocaleDateString(undefined, { weekday: "short" }),
          longLabel: date.toLocaleDateString(undefined, {
            weekday: "long",
            day: "numeric",
            month: "long",
          }),
        };
      });
    },

    totalHours() {
      return this.days.reduce((sum, day) => sum + (day.hours || 0), 0);
    },

    remainingHours() {
      return TARGETS.weeklyHours - this.totalHours;
    },
  },

  mounted() {
    // Only needed to move a running session forward
    this.ticker = setInterval(() => {
      if (this.liveSince) this.now = Date.now();
    }, 30_000);
  },

  beforeUnmount() {
    clearInterval(this.ticker);
  },

  methods: {
    formatHours,
    formatClockHours,
  },
};
</script>

<style scoped>
.week-card {
  display: flex;
  flex-direction: column;
  gap: 20px;
  min-width: 0;
}

.week-head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
}

.subtitle {
  margin: 4px 0 0;
  color: var(--tm-ink-muted);
}

.week-footer {
  margin: 0;
  color: var(--tm-ink-muted);
}

.week-footer strong {
  color: var(--tm-ink);
  font-size: 22px;
}

.week-total strong {
  font-size: 22px;
}

.week-total span {
  color: var(--tm-ink-muted);
}

.days {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.day {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.day-name {
  font-size: var(--tm-fs-small);
  font-weight: 700;
}

.day.today .day-name {
  color: var(--tm-accent-strong);
  font-weight: 800;
}

.day.future .day-name,
.day.future .day-hours {
  color: var(--tm-ink-muted);
}

.day-box {
  width: 100%;
  height: 150px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-input);
  background: var(--tm-surface);
  display: flex;
  align-items: flex-end;
  overflow: hidden;
}

.day.future .day-box {
  border: 2px dashed var(--tm-line-dashed);
  background: transparent;
}

.day-fill {
  width: 100%;
  background: var(--tm-primary);
}

.day.today .day-fill {
  background: var(--tm-accent);
}

/* A session is running today (must beat ".day.today .day-fill") */
.day.today .day-fill.live {
  background: repeating-linear-gradient(
    -45deg,
    var(--tm-accent) 0 8px,
    #f39a6b 8px 16px
  );
}

.day-hours {
  font-weight: 700;
}

@media (max-width: 640px) {
  .days {
    gap: 6px;
  }

  .day-box {
    height: 110px;
  }

  .day-hours {
    font-size: 13px;
  }
}
</style>
