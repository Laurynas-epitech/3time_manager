<template>
  <div class="clock-screen">
    <section class="hello">
      <p>{{ greeting }}</p>
      <h2>{{ me.username }}</h2>
      <span>{{ today }}</span>
    </section>

    <section class="card">
      <ClockManager
        :user-id="me.id"
        :can-clock="true"
      />
    </section>

    <section class="card week">
      <div>
        <span class="label">This week</span>
        <strong>{{ weekHours.toFixed(1) }} h</strong>
      </div>
      <div>
        <span class="label">Shifts</span>
        <strong>{{ weekShifts }}</strong>
      </div>
    </section>

    <section class="card">
      <div class="recent-head">
        <h3>Recent shifts</h3>
        <router-link to="/history">See all</router-link>
      </div>

      <p
        v-if="recent.length === 0"
        class="muted"
      >
        No shifts recorded yet.
      </p>

      <ul
        v-else
        class="recent"
      >
        <li
          v-for="wt in recent"
          :key="wt.id"
        >
          <span>{{ formatDay(wt.start) }}</span>
          <span class="muted">{{ formatTime(wt.start) }} to {{ formatTime(wt.end) }}</span>
          <strong>{{ hours(wt).toFixed(1) }} h</strong>
        </li>
      </ul>
    </section>
  </div>
</template>

<script>
import auth from "../../auth";
import { cachedGet } from "../../offline";
import ClockManager from "../../components/ClockManager.vue";

export default {
  name: "ClockView",

  components: { ClockManager },

  data() {
    return { workingTimes: [] };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    greeting() {
      const h = new Date().getHours();
      return h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    },

    today() {
      return new Date().toLocaleDateString(undefined, {
        weekday: "long",
        day: "numeric",
        month: "long",
      });
    },

    // Monday 00:00 of the current week
    weekStart() {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
      return d;
    },

    thisWeek() {
      return this.workingTimes.filter((wt) => new Date(wt.start) >= this.weekStart);
    },

    weekHours() {
      return this.thisWeek.reduce((sum, wt) => sum + this.hours(wt), 0);
    },

    weekShifts() {
      return this.thisWeek.length;
    },

    recent() {
      return [...this.workingTimes]
        .sort((a, b) => new Date(b.start) - new Date(a.start))
        .slice(0, 3);
    },
  },

  mounted() {
    this.load();
    window.addEventListener("tm:synced", this.load);
  },

  unmounted() {
    window.removeEventListener("tm:synced", this.load);
  },

  methods: {
    async load() {
      if (!this.me) return;

      try {
        const { data } = await cachedGet(`/workingtime/${this.me.id}`);
        const list = data.data ?? data;
        this.workingTimes = Array.isArray(list) ? list : [];
      } catch {
        this.workingTimes = [];
      }
    },

    hours(wt) {
      return (new Date(wt.end) - new Date(wt.start)) / 3600000;
    },

    formatDay(value) {
      return new Date(value).toLocaleDateString(undefined, {
        weekday: "short",
        day: "numeric",
        month: "short",
      });
    },

    formatTime(value) {
      return new Date(value).toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      });
    },
  },
};
</script>

<style scoped>
.clock-screen {
  display: grid;
  gap: 14px;
}

.hello p {
  margin: 0;
  color: #6b7280;
}

.hello h2 {
  margin: 2px 0;
  font-size: 28px;
}

.hello span {
  color: #6b7280;
  font-size: 14px;
}

.week {
  display: grid;
  grid-template-columns: 1fr 1fr;
}

.week div + div {
  border-left: 1px solid #e5e7eb;
  padding-left: 16px;
}

.label {
  display: block;
  color: #6b7280;
  font-size: 13px;
}

.week strong {
  font-size: 26px;
}

.recent-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.recent-head h3 {
  margin: 0;
  font-size: 17px;
}

.recent-head a {
  color: #4f46e5;
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
}

.recent {
  list-style: none;
  margin: 0;
  padding: 0;
}

.recent li {
  display: grid;
  grid-template-columns: 1fr auto;
  grid-template-areas:
    "day hours"
    "time hours";
  padding: 10px 0;
  border-bottom: 1px solid #f1f2f4;
}

.recent li:last-child {
  border-bottom: none;
}

.recent li span:first-child {
  grid-area: day;
  font-weight: 600;
}

.recent li .muted {
  grid-area: time;
}

.recent li strong {
  grid-area: hours;
  align-self: center;
  font-size: 17px;
}

.muted {
  color: #6b7280;
  font-size: 14px;
}
</style>
