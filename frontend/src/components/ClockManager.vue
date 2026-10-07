<template>
  <div class="clock-manager">
    <div
      class="status"
      :class="clockIn ? 'working' : 'not-working'"
    >
      <span class="status-dot"></span>

      <div>
        <span class="status-label">
          Status
        </span>

        <strong>
          {{
            !loaded
              ? "Checking..."
              : clockIn
                ? "Currently working"
                : "Not working"
          }}
        </strong>
      </div>
    </div>

    <div
      v-if="startDateTime"
      class="clock-info"
    >
      <span>Clocked in at</span>

      <strong>
        {{ formatDateTime(startDateTime) }}
      </strong>
    </div>

    <p
      v-if="pending"
      class="offline-note"
    >
      Saved on this device. It will sync automatically when you're back online.
    </p>

    <button
      v-if="canClock"
      class="clock-button"
      :disabled="busy || !loaded"
      @click="clock"
    >
      {{
        clockIn
          ? "Clock Out"
          : "Clock In"
      }}
    </button>
  </div>
</template>

<script>
import auth from "../auth";
import { cachedGet, queueClock, pendingClocks } from "../offline";
import { vibrate, scheduleClockOutReminder, cancelClockOutReminder } from "../native";

export default {
  name: "ClockManager",

  props: {
    userId: {
      type: Number,
      required: true,
    },

    canClock: {
      type: Boolean,
      default: true,
    },
  },

  data() {
    return {
      serverClocks: [],
      busy: false,
      loaded: false,
    };
  },

  computed: {
    // Clock actions waiting to be sent (offline).
    pending() {
      return pendingClocks(this.userId).length;
    },

    // Server history + unsynced actions: the status is right even offline.
    latest() {
      const all = [...this.serverClocks, ...pendingClocks(this.userId)];
      return all.length ? all[all.length - 1] : null;
    },

    clockIn() {
      return !!this.latest?.status;
    },

    startDateTime() {
      return this.clockIn ? this.latest.time : null;
    },
  },

  watch: {
    userId: {
      immediate: true,

      handler() {
        this.loaded = false;
        this.refresh();
      },
    },
  },

  mounted() {
    window.addEventListener("tm:synced", this.refresh);
  },

  unmounted() {
    window.removeEventListener("tm:synced", this.refresh);
  },

  methods: {
    async refresh() {
      if (!this.userId) return;

      try {
        const { data } = await cachedGet(`/clock/${this.userId}`);
        const clocks = data.data ?? data;
        this.serverClocks = Array.isArray(clocks) ? clocks : [];
      } catch (error) {
        console.error("REFRESH CLOCK ERROR:", error);
        this.serverClocks = [];
      } finally {
        this.loaded = true;
      }
    },

    async clock() {
      if (!this.userId || this.busy) return;

      this.busy = true;

      try {
        const status = !this.clockIn;

        // Saved locally first with the current time, sent when possible.
        const action = await queueClock(this.userId, status);

        vibrate("success");

        if (this.userId === auth.state.user?.id) {
          if (status) scheduleClockOutReminder(action.time);
          else cancelClockOutReminder();
        }
      } finally {
        this.busy = false;
      }
    },

    formatDateTime(value) {
      return new Date(value).toLocaleString(undefined, {
        day: "2-digit",
        month: "short",
        hour: "2-digit",
        minute: "2-digit",
      });
    },
  },
};
</script>

<style scoped>
.clock-manager {
  display: grid;
  gap: 18px;
}

.status {
  display: flex;
  align-items: center;
  gap: 12px;

  padding: 16px;

  border-radius: 12px;
}

.status.working {
  background: #ecfdf5;
}

.status.not-working {
  background: #f8fafc;
}

.status-dot {
  width: 12px;
  height: 12px;

  border-radius: 50%;

  background: #94a3b8;
}

.working .status-dot {
  background: #22c55e;
}

.status > div {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.status-label {
  font-size: 12px;
  color: #6b7280;
}

.working strong {
  color: #15803d;
}

.not-working strong {
  color: #475569;
}

.clock-info {
  display: flex;
  justify-content: space-between;

  padding: 12px;

  border-bottom: 1px solid #e5e7eb;

  font-size: 13px;
}

.clock-info span {
  color: #6b7280;
}

.clock-button {
  width: 100%;
  padding: 13px;
}

.offline-note {
  margin: 0;
  padding: 10px 12px;
  border-radius: 9px;
  background: #fef3c7;
  color: #92400e;
  font-size: 13px;
}
</style>