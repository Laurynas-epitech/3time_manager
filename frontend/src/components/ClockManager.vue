<template>
  <section
    class="tm-card tm-card--primary clock-hero"
    aria-labelledby="clock-greeting"
  >
    <div class="context">
      <span>{{ todayLabel }}</span>
      <span v-if="teamNames.length"> · {{ teamNames.join(", ") }}</span>
    </div>

    <p
      v-if="isSelf && !teamNames.length && teamsLoaded"
      class="no-team"
    >
      You're not in a team yet. An admin can add you.
    </p>

    <h1
      id="clock-greeting"
      class="greeting"
    >
      {{ greeting }}
    </h1>

    <div class="clock-row">
      <button
        v-if="canClock"
        type="button"
        class="clock-button"
        :class="{ 'is-in': clockIn }"
        :disabled="loading || saving"
        @click="clock"
      >
        {{ clockIn ? "Clock out" : "Clock in" }}
      </button>

      <div
        v-if="loading"
        class="skeleton figures-skeleton"
        aria-hidden="true"
      ></div>

      <div
        v-else
        class="figures"
        aria-live="polite"
      >
        <template v-if="clockIn">
          <span class="figure-label">Current session</span>
          <span class="figure-value tm-num timer">{{ sessionTimer }}</span>
          <span class="figure-sub">
            In since {{ formatTime(startDateTime) }} · {{ formatHours(workedTodayHours) }} today
          </span>
        </template>

        <template v-else>
          <span class="figure-label">Worked today</span>
          <span class="figure-value tm-num">{{ formatHours(workedTodayHours) }}</span>
          <span
            v-if="lastOut"
            class="figure-sub"
          >
            Last out at {{ formatTime(lastOut) }}
          </span>
        </template>
      </div>
    </div>

    <p
      v-if="error"
      class="clock-error"
      role="alert"
    >
      {{ error }}
    </p>
  </section>
</template>

<script>
import auth from "../auth";
import { getAttendance, recordAttendance, attendanceState } from "../services/attendance";
import { getDemoAttendance, toggleDemoClock } from "../services/demoAttendance";
import {
  addDays,
  formatHours,
  formatTime,
  formatTimer,
  hoursByDay,
  startOfDay,
  toDateKey,
} from "../time";

export default {
  name: "ClockManager",
  // `status` tells the dashboard whether a session is running (week card)
  emits: ["clock-changed", "status"],

  props: {
    userId: {
      type: Number,
      required: true,
    },

    canClock: {
      type: Boolean,
      default: true,
    },

    userName: {
      type: String,
      default: "",
    },

    // true on your own dashboard (changes the greeting)
    isSelf: {
      type: Boolean,
      default: true,
    },

    teamNames: {
      type: Array,
      default: () => [],
    },

    teamsLoaded: {
      type: Boolean,
      default: false,
    },

    // Completed sessions of the user, used for "Worked today" and "Last out"
    workingTimes: {
      type: Array,
      default: () => [],
    },
  },

  data() {
    return {
      startDateTime: null,
      clockIn: false,
      loading: false,
      saving: false,
      error: "",
      now: Date.now(),
      ticker: null,
    };
  },

  computed: {
    attendanceRevision() { return attendanceState.revision; },
    todayLabel() {
      return new Date(this.now).toLocaleDateString(undefined, {
        weekday: "long",
        day: "numeric",
        month: "long",
      });
    },

    greeting() {
      if (this.isSelf) {
        return this.clockIn ? "You're on the clock." : `Ready when you are, ${this.userName}.`;
      }

      return this.clockIn ? `${this.userName} is on the clock.` : `${this.userName} is not clocked in.`;
    },

    // Completed sessions today plus the running one
    workedTodayHours() {
      const today = startOfDay(new Date(this.now));
      const tomorrow = addDays(today, 1);
      const sessions = [...this.workingTimes];

      if (this.clockIn && this.startDateTime) {
        sessions.push({ start: this.startDateTime, end: new Date(this.now) });
      }

      return hoursByDay(sessions, today, tomorrow)[toDateKey(today)] ?? 0;
    },

    sessionTimer() {
      return formatTimer(this.now - new Date(this.startDateTime));
    },

    // End of the latest session finished today
    lastOut() {
      const todayKey = toDateKey(new Date(this.now));
      const ends = this.workingTimes
        .map((w) => new Date(w.end))
        .filter((end) => toDateKey(end) === todayKey);

      return ends.length ? new Date(Math.max(...ends)) : null;
    },
  },

  watch: {
    attendanceRevision() { if (!auth.isDemo()) this.refresh(false); },
    userId: {
      immediate: true,

      handler() {
        this.refresh();
      },
    },
  },

  mounted() {
    // Keeps the live timer and "today" up to date
    this.ticker = setInterval(() => {
      this.now = Date.now();
    }, 1000);
  },

  beforeUnmount() {
    clearInterval(this.ticker);
  },

  methods: {
    formatHours,
    formatTime,

    async refresh(refresh = true) {
      if (!this.userId) return;
      this.loading = true;
      this.error = "";

      try {
        const attendance = auth.isDemo()
          ? await getDemoAttendance(this.userId)
          : await getAttendance(this.userId, { refresh });
        this.clockIn = attendance.clockIn;
        this.startDateTime = attendance.startDateTime;
      } catch (error) {
        console.error("REFRESH CLOCK ERROR:", error);
        this.error = error.message || "Unable to load attendance status. Please try again.";
      } finally {
        this.loading = false;
        this.$emit("status", { clockIn: this.clockIn, startDateTime: this.startDateTime });
      }
    },

    async clock() {
      if (!this.userId || this.loading || this.saving) return;
      this.saving = true;
      this.error = "";

      try {
        if (auth.isDemo()) await toggleDemoClock(this.userId);
        else await recordAttendance(this.userId, !this.clockIn);
        await this.refresh(false);
        this.$emit("clock-changed");
      } catch (error) {
        console.error("CLOCK ERROR:", error);
        this.error = error.message || "Unable to save attendance. Please refresh and try again.";
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>

<style scoped>
.clock-hero {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 24px;
  padding: 32px;
}

.context {
  font-weight: 600;
  opacity: 0.92;
}

.no-team {
  margin: -14px 0 0;
  font-size: 14px;
  opacity: 0.92;
}

.greeting {
  margin: 0;
  font-size: var(--tm-fs-hero);
  font-weight: 800;
  line-height: 0.95;
  letter-spacing: -0.04em;
}

.clock-row {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
}

.clock-button {
  width: 148px;
  height: 148px;
  padding: 0 20px;
  border-radius: 50%;
  border: 3px solid var(--tm-ink);
  background: var(--tm-accent);
  color: var(--tm-ink);
  box-shadow: var(--tm-shadow-sm);
  font-family: var(--tm-font-display);
  font-size: 26px;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1.05;
}

.clock-button.is-in {
  background: var(--tm-ink);
  color: var(--tm-ground);
}

.clock-button:focus-visible {
  outline-color: #fff;
}

.figures {
  display: flex;
  flex-direction: column;
}

.figure-label,
.figure-sub {
  font-size: 14px;
  opacity: 0.92;
}

.figure-value {
  font-size: 40px;
  font-weight: 700;
}

.timer {
  font-variant-numeric: tabular-nums;
}

.figures-skeleton {
  width: 180px;
  height: 80px;
  background: rgba(255, 255, 255, 0.25);
}

.clock-error {
  margin: 0;
  padding: 8px 14px;
  border-radius: var(--tm-radius-input);
  background: var(--tm-surface);
  color: var(--tm-danger);
  font-size: 14px;
  font-weight: 600;
}

@media (max-width: 640px) {
  .greeting {
    font-size: 40px;
  }
}
</style>
