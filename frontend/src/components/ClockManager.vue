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
            clockIn
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

    <button
      v-if="canClock"
      class="clock-button"
      :disabled="loading || saving"
      @click="clock"
    >
      {{
        clockIn
          ? "Clock Out"
          : "Clock In"
      }}
    </button>
    <p v-if="error" role="alert">{{ error }}</p>
  </div>
</template>

<script>
import api from "../api";

export default {
  name: "ClockManager",
  emits: ["clock-changed"],

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
      startDateTime: null,
      clockIn: false,
      loading: false,
      saving: false,
      error: "",
    };
  },

  watch: {
    userId: {
      immediate: true,

      handler() {
        this.refresh();
      },
    },
  },

  methods: {
    async refresh() {
      if (!this.userId) return;
      this.loading = true;
      this.error = "";

      try {
        const response = await api.get(
  `/clock/${this.userId}`
);

        const data =
          response.data.data ?? response.data;

        if (
          Array.isArray(data) &&
          data.length > 0
        ) {
          const latestClock =
            data[data.length - 1];

          this.clockIn =
            latestClock.status;

          this.startDateTime =
            latestClock.status
              ? latestClock.time
              : null;
        } else {
          this.clockIn = false;
          this.startDateTime = null;
        }
      } catch (error) {
        console.error(
          "REFRESH CLOCK ERROR:",
          error
        );

        this.error = "Unable to load attendance status. Please try again.";
      } finally {
        this.loading = false;
      }
    },

    async clock() {
      if (!this.userId || this.loading || this.saving) return;
      this.saving = true;
      this.error = "";

      try {
        await api.post(
  `/clock/${this.userId}`,
  {
    clock: {
      time: new Date().toISOString(),
      status: !this.clockIn,
    },
  }
);
        await this.refresh();
        this.$emit("clock-changed");
      } catch (error) {
        console.error(
          "CLOCK ERROR:",
          error
        );
        this.error = "Unable to save attendance. Please refresh and try again.";
      } finally {
        this.saving = false;
      }
    },

    formatDateTime(value) {
      return new Date(
        value
      ).toLocaleString(undefined, {
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
</style>
