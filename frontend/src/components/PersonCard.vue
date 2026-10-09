<template>
  <button
    type="button"
    class="person-card"
    :class="{ selected, self }"
    :aria-pressed="String(selected)"
    @click="$emit('select')"
  >
    <span
      class="avatar"
      :class="`avatar--${role}`"
      aria-hidden="true"
    >
      {{ name.charAt(0).toLowerCase() }}
    </span>

    <span class="who">
      <span class="name">{{ self ? "you" : name }}</span>
      <span
        v-if="self"
        class="status"
      >
        your own hours
      </span>
      <span
        v-else
        class="status"
        :class="{ live: clockedIn }"
      >
        <span
          class="dot"
          aria-hidden="true"
        ></span>
        {{ statusText }}
      </span>
    </span>

    <span
      v-if="!self"
      class="today tm-num"
      :aria-label="`${formatHours(todayHours)} today`"
    >
      {{ formatClockHours(todayHours) }}
    </span>
  </button>
</template>

<script>
import { formatClockHours, formatHours, formatTime } from "../time";

export default {
  name: "PersonCard",

  props: {
    name: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      default: "employee",
    },

    selected: {
      type: Boolean,
      default: false,
    },

    // The dashed "you" card
    self: {
      type: Boolean,
      default: false,
    },

    clockedIn: {
      type: Boolean,
      default: false,
    },

    inSince: {
      type: [String, Date],
      default: null,
    },

    lastOut: {
      type: [String, Date],
      default: null,
    },

    todayHours: {
      type: Number,
      default: 0,
    },
  },

  emits: ["select"],

  computed: {
    statusText() {
      if (this.clockedIn) return `in since ${formatTime(this.inSince)}`;
      if (this.lastOut) return `out since ${formatTime(this.lastOut)}`;
      return "not in today";
    },
  },

  methods: {
    formatClockHours,
    formatHours,
  },
};
</script>

<style scoped>
.person-card {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 100%;
  min-height: 88px;
  padding: 16px 18px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-tile);
  background: var(--tm-surface);
  color: var(--tm-ink);
  text-align: left;
  font-weight: 500;
}

.person-card.selected {
  box-shadow: 6px 6px 0 var(--tm-primary);
}

.person-card.self {
  border-style: dashed;
  border-color: var(--tm-line-dashed);
  background: transparent;
}

.person-card.self.selected {
  border-color: var(--tm-ink);
  box-shadow: var(--tm-shadow-sm);
}

.avatar {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border: var(--tm-border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--tm-font-display);
  font-size: 22px;
  font-weight: 700;
  background: var(--tm-primary-soft);
}

.avatar--manager {
  background: var(--tm-accent-soft);
}

.avatar--admin {
  background: var(--tm-sunken);
}

.who {
  display: flex;
  flex-direction: column;
  min-width: 0;
  flex: 1;
}

.name {
  font-size: 17px;
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: var(--tm-ink-muted);
}

.status.live {
  color: var(--tm-live-text);
  font-weight: 600;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--tm-line-dashed);
}

.status.live .dot {
  background: var(--tm-live);
}

.today {
  font-size: 22px;
}
</style>
