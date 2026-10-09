<template>
  <div class="punches">
    <!-- Period filter (editable list only) -->
    <div
      v-if="canEdit"
      class="punch-filters"
    >
      <RangeChips
        v-model="range"
        :options="ranges"
        label="Punches period"
      />

      <div
        v-if="range === 'pick'"
        class="pick-dates"
      >
        <label
          class="tm-label"
          for="punches-from"
        >
          From
          <input
            id="punches-from"
            v-model="from"
            class="tm-input"
            type="date"
          />
        </label>
        <label
          class="tm-label"
          for="punches-to"
        >
          To
          <input
            id="punches-to"
            v-model="to"
            class="tm-input"
            type="date"
          />
        </label>
      </div>
    </div>

    <div
      v-if="loading && workingTimes.length === 0"
      class="punch-grid"
      aria-hidden="true"
    >
      <div
        v-for="n in 4"
        :key="n"
        class="skeleton punch-skeleton"
      ></div>
    </div>

    <p
      v-else-if="error"
      class="error-msg"
      role="alert"
    >
      {{ error }}
    </p>

    <div
      v-else-if="sorted.length === 0 && !liveSince"
      class="empty"
    >
      {{ canEdit ? "No punches in this period." : "No punches yet. Clock in to start your card." }}
    </div>

    <!-- Read-only cards (your own dashboard) -->
    <ul
      v-else-if="!canEdit"
      class="punch-grid"
    >
      <li
        v-for="workingTime in visible"
        :key="workingTime.id"
        class="punch-card"
      >
        <span
          class="punch-date"
          :class="{ today: isToday(workingTime.start) }"
        >
          {{ formatShortDate(workingTime.start) }}
        </span>
        <span class="punch-duration tm-num">{{ formatHours(durationHours(workingTime)) }}</span>
        <span class="punch-range">
          {{ formatTime(workingTime.start) }} → {{ formatTime(workingTime.end) }}
        </span>
      </li>
    </ul>

    <!-- Editable list (managers and admins) -->
    <ul
      v-else
      class="punch-list"
    >
      <li
        v-if="liveSince && liveInRange"
        class="punch-row"
      >
        <span class="punch-date">{{ formatShortDate(liveSince) }}</span>
        <span class="punch-range">
          {{ formatTime(liveSince) }} → <strong class="still-in">still in</strong>
        </span>
        <span class="punch-duration tm-num">{{ formatHours(liveHours) }}</span>
        <span class="edit-placeholder"></span>
      </li>

      <li
        v-for="workingTime in visible"
        :key="workingTime.id"
        class="punch-item"
      >
        <div
          class="punch-row"
          :class="{ selected: workingTime.id === editingId }"
        >
          <span class="punch-date">{{ formatShortDate(workingTime.start) }}</span>
          <span class="punch-range">
            {{ formatTime(workingTime.start) }} → {{ formatTime(workingTime.end) }}
          </span>
          <span class="punch-duration tm-num">{{ formatHours(durationHours(workingTime)) }}</span>
          <button
            type="button"
            class="tm-btn edit-btn"
            :disabled="workingTime.pending || !online"
            :aria-expanded="String(workingTime.id === editingId)"
            :aria-label="`Edit punch of ${formatShortDate(workingTime.start)}, ${formatTime(workingTime.start)} to ${formatTime(workingTime.end)}`"
            @click="toggleEdit(workingTime)"
          >
            {{ workingTime.id === editingId ? "Close" : "Edit" }}
          </button>
        </div>

        <!-- Inline edit: same Day / In / Out fields, plus Delete -->
        <WorkingTime
          v-if="workingTime.id === editingId"
          class="inline-edit"
          :user-id="userId"
          :working-time="workingTime"
          @saved="afterChange"
          @deleted="afterChange"
          @cancel-edit="editingId = null"
        />
      </li>
    </ul>

    <button
      v-if="filtered.length > visible.length"
      type="button"
      class="tm-btn more-btn"
      @click="shown += pageSize"
    >
      Show more
    </button>
  </div>
</template>

<script>
import auth from "../auth";
import { getAttendance, attendanceState } from "../services/attendance";
import { getDemoAttendance } from "../services/demoAttendance";
import RangeChips from "./RangeChips.vue";
import WorkingTime from "./WorkingTime.vue";
import {
  addDays,
  durationHours,
  formatHours,
  formatShortDate,
  formatTime,
  fromDateKey,
  startOfDay,
  startOfWeek,
  toDateKey,
} from "../time";

export default {
  name: "WorkingTimes",

  components: { RangeChips, WorkingTime },

  props: {
    userId: {
      type: Number,
      required: true,
    },

    canEdit: {
      type: Boolean,
      default: false,
    },

    // Start of the running session, shown as "still in"
    liveSince: {
      type: [String, Date],
      default: null,
    },

    pageSize: {
      type: Number,
      default: 8,
    },
  },

  // `loaded` shares the fetched entries with the rest of the page,
  // `changed` tells it a punch was edited or deleted here.
  emits: ["loaded", "changed"],

  data() {
    const today = startOfDay(new Date());

    return {
      workingTimes: [],
      loading: false,
      error: "",
      shown: this.pageSize,
      editingId: null,
      range: "this-week",
      ranges: [
        { id: "this-week", label: "This week" },
        { id: "last-4-weeks", label: "Last 4 weeks" },
        { id: "pick", label: "Pick dates" },
      ],
      from: toDateKey(addDays(today, -30)),
      to: toDateKey(today),
      now: Date.now(),
      ticker: null,
    };
  },

  computed: {
    online() { return attendanceState.online; },
    attendanceRevision() { return attendanceState.revision; },
    // [start, end) of the selected period; the read-only cards are not filtered
    period() {
      const today = startOfDay(new Date(this.now));

      if (this.range === "this-week") return [startOfWeek(today), addDays(today, 1)];
      if (this.range === "last-4-weeks") return [addDays(startOfWeek(today), -21), addDays(today, 1)];
      if (!this.from || !this.to) return [today, today];
      return [fromDateKey(this.from), addDays(fromDateKey(this.to), 1)];
    },

    // Newest first
    sorted() {
      return [...this.workingTimes].sort((a, b) => new Date(b.start) - new Date(a.start));
    },

    filtered() {
      if (!this.canEdit) return this.sorted;

      const [from, to] = this.period;
      return this.sorted.filter((w) => new Date(w.start) < to && new Date(w.end) > from);
    },

    visible() {
      return this.filtered.slice(0, this.shown);
    },

    liveInRange() {
      return new Date(this.liveSince) < this.period[1];
    },

    liveHours() {
      return (this.now - new Date(this.liveSince)) / 3_600_000;
    },
  },

  watch: {
    attendanceRevision() { if (!auth.isDemo()) this.getWorkingTimes(false); },
    userId: {
      immediate: true,

      handler() {
        this.shown = this.pageSize;
        this.editingId = null;
        this.workingTimes = [];
        this.getWorkingTimes();
      },
    },

    range() {
      this.shown = this.pageSize;
    },
  },

  mounted() {
    this.ticker = setInterval(() => {
      if (this.liveSince) this.now = Date.now();
    }, 30_000);
  },

  beforeUnmount() {
    clearInterval(this.ticker);
  },

  methods: {
    durationHours,
    formatHours,
    formatShortDate,
    formatTime,

    isToday(value) {
      return toDateKey(new Date(value)) === toDateKey(new Date());
    },

    toggleEdit(workingTime) {
      this.editingId = this.editingId === workingTime.id ? null : workingTime.id;
    },

    async afterChange() {
      this.editingId = null;
      await this.getWorkingTimes();
      this.$emit("changed");
    },

    async getWorkingTimes(refresh = true) {
      if (!this.userId) {
        this.workingTimes = [];
        return;
      }

      this.loading = true;
      this.error = "";

      try {
        const attendance = auth.isDemo()
          ? await getDemoAttendance(this.userId)
          : await getAttendance(this.userId, { refresh });
        this.workingTimes = attendance.workingTimes;
      } catch (error) {
        console.error("GET WORKING TIMES ERROR:", error);
        this.workingTimes = [];
        this.error = error.message || "Could not load the punches.";
      } finally {
        this.loading = false;
        this.$emit("loaded", this.workingTimes);
      }
    },
  },
};
</script>

<style scoped>
.punches {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap);
}

.punch-filters {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap);
}

.pick-dates {
  display: flex;
  flex-wrap: wrap;
  gap: var(--tm-gap);
}

.punch-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(240px, 100%), 1fr));
  gap: var(--tm-gap);
  margin: 0;
  padding: 0;
  list-style: none;
}

.punch-card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 18px;
  background: var(--tm-surface);
  border: var(--tm-border);
  border-radius: var(--tm-radius-tile);
}

.punch-skeleton {
  height: 112px;
}

.punch-date {
  font-size: 15px;
  font-weight: 700;
}

.punch-card .punch-date {
  font-size: 14px;
  color: var(--tm-ink-muted);
}

.punch-card .punch-date.today {
  color: var(--tm-accent-strong);
}

.punch-duration {
  font-size: 28px;
  letter-spacing: -0.02em;
}

.punch-range {
  color: var(--tm-ink-muted);
}

.still-in {
  color: var(--tm-live-text);
}

.punch-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.punch-item,
.punch-list > .punch-row {
  border-bottom: 2px dashed var(--tm-divider);
}

.punch-item:last-child {
  border-bottom: none;
}

.punch-row {
  display: grid;
  grid-template-columns: minmax(110px, 0.6fr) minmax(150px, 2fr) auto 92px;
  align-items: center;
  gap: var(--tm-gap);
  min-height: 68px;
  padding: 10px 0;
}

.punch-row.selected {
  font-weight: 700;
}

.punch-row .punch-duration {
  font-size: 20px;
  text-align: right;
}

.edit-btn {
  min-height: var(--tm-hit);
  padding: 0 18px;
  background: transparent;
  color: var(--tm-ink);
}

.inline-edit {
  margin: 0 0 16px;
  padding: 18px;
  border-radius: var(--tm-radius-tile);
  background: var(--tm-accent-soft);
}

.more-btn {
  align-self: center;
  background: transparent;
  color: var(--tm-ink);
}

.empty {
  padding: 28px;
  border: 2px dashed var(--tm-line-dashed);
  border-radius: var(--tm-radius-tile);
  color: var(--tm-ink-muted);
  text-align: center;
  font-weight: 600;
}

/* Phones: date + duration on top, times + Edit below */
@media (max-width: 640px) {
  .punch-row {
    grid-template-columns: 1fr auto;
    grid-template-areas:
      "date duration"
      "range edit";
    row-gap: 4px;
  }

  .punch-row .punch-date {
    grid-area: date;
  }

  .punch-row .punch-duration {
    grid-area: duration;
  }

  .punch-row .punch-range {
    grid-area: range;
  }

  .punch-row .edit-btn {
    grid-area: edit;
  }

  .edit-placeholder {
    display: none;
  }
}
</style>
