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
      class="clock-button"
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
import axios from "axios";

export default {
  name: "ClockManager",

  props: {
    userId: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      startDateTime: null,
      clockIn: false,
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

      try {
        const response = await axios.get(
  `http://localhost:4000/api/clock/${this.userId}`
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

        this.clockIn = false;
        this.startDateTime = null;
      }
    },

    async clock() {
      if (!this.userId) return;

      try {
        await axios.post(
  `http://localhost:4000/api/clock/${this.userId}`,
  {
    clock: {
      time: new Date().toISOString(),
      status: !this.clockIn,
    },
  }
);
        await this.refresh();
      } catch (error) {
        console.error(
          "CLOCK ERROR:",
          error
        );
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