<template>
  <div class="view">
    <p
      v-if="error"
      class="error-msg"
      role="alert"
    >
      {{ error }}
    </p>

    <div
      v-else-if="!loaded"
      class="skeleton title-skeleton"
      aria-hidden="true"
    ></div>

    <section
      v-else-if="groups.length === 0"
      class="tm-card tm-card--dashed empty"
    >
      You don't manage a team yet. An admin can assign you one.
    </section>

    <template v-else>
      <!-- TEAM SWITCHER (several teams, or admin) -->
      <RangeChips
        v-if="groups.length > 1"
        :model-value="String(groupId)"
        :options="groups.map((g) => ({ id: String(g.id), label: g.name }))"
        label="Team"
        @update:model-value="selectGroup"
      />

      <!-- TITLE -->
      <header class="team-title">
        <h1 class="tm-h1">{{ group.name }}</h1>
        <p>{{ onClockSummary }}</p>
      </header>

      <!-- PEOPLE -->
      <div
        class="people"
        role="group"
        aria-label="Choose whose hours to show"
      >
        <PersonCard
          v-for="person in people"
          :key="person.id"
          :name="person.username"
          :role="person.role"
          :selected="person.id === selectedId"
          :clocked-in="statusOf(person.id).clockIn"
          :in-since="statusOf(person.id).since"
          :last-out="statusOf(person.id).lastOut"
          :today-hours="statusOf(person.id).todayHours"
          @select="selectPerson(person.id)"
        />

        <PersonCard
          self
          :name="me.username"
          :role="me.role"
          :selected="selectedId === me.id"
          @select="selectPerson(me.id)"
        />

        <p
          v-if="people.length === 0"
          class="hint no-people"
        >
          No one in this team yet. Add people from the Teams page.
        </p>
      </div>

      <template v-if="selected">
        <!-- WEEK + ADD A PUNCH -->
        <div class="top-row">
          <WeekCard
            class="week"
            :title="selected.id === me.id ? 'Your week' : `${selected.username}'s week`"
            :subtitle="`${selected.email} · ${selected.role}`"
            :working-times="workingTimes"
            :live-since="selectedStatus.clockIn ? selectedStatus.since : null"
          >
            <template
              v-if="selectedStatus.clockIn"
              #aside
            >
              <div
                class="live-box"
                role="timer"
                :aria-label="`Clocked in for ${liveTimer}`"
              >
                <span class="live-label">Clocked in · live</span>
                <span class="live-timer tm-num">{{ liveTimer }}</span>
              </div>
            </template>
          </WeekCard>

          <section class="tm-card tm-card--accent add-punch">
            <WorkingTime
              :key="selected.id"
              :user-id="selected.id"
              :person-name="selected.id === me.id ? 'yourself' : selected.username"
              @saved="refreshSelected"
            />
          </section>
        </div>

        <!-- PUNCHES -->
        <section
          class="card punches-card"
          aria-labelledby="punches-title"
        >
          <h2
            id="punches-title"
            class="tm-h2"
          >
            Punches
          </h2>

          <WorkingTimes
            ref="workingTimes"
            :user-id="selected.id"
            can-edit
            :live-since="selectedStatus.clockIn ? selectedStatus.since : null"
            @loaded="workingTimes = $event"
            @changed="refreshSelected(false)"
          />
        </section>

        <!-- DAILY / WEEKLY HOURS OVER A PERIOD -->
        <HoursReport
          ref="hoursReport"
          :user-id="selected.id"
          :title="selected.id === me.id ? 'How your weeks add up' : `How ${selected.username}'s weeks add up`"
        />
      </template>
    </template>
  </div>
</template>

<script>
import api, { errorMessage } from "../api";
import auth from "../auth";
import { getAttendance } from "../services/attendance";
import HoursReport from "../components/HoursReport.vue";
import PersonCard from "../components/PersonCard.vue";
import RangeChips from "../components/RangeChips.vue";
import WeekCard from "../components/WeekCard.vue";
import WorkingTime from "../components/WorkingTime.vue";
import WorkingTimes from "../components/WorkingTimes.vue";
import { addDays, formatTimer, hoursByDay, startOfDay, toDateKey } from "../time";

const EVERYONE = "everyone";
const STATUS_REFRESH_MS = 60_000;

export default {
  name: "MyTeamView",

  components: { HoursReport, PersonCard, RangeChips, WeekCard, WorkingTime, WorkingTimes },

  data() {
    return {
      teams: [],
      directory: [],
      loaded: false,
      error: "",
      groupId: null,
      selectedId: null,
      // { [userId]: { clockIn, since, lastOut, todayHours } }
      statuses: {},
      workingTimes: [],
      now: Date.now(),
      ticker: null,
      poller: null,
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    isAdmin() {
      return auth.hasRole("admin");
    },

    // Managers: the teams they run. Admins: every team plus "Everyone".
    groups() {
      const teams = this.isAdmin
        ? this.teams
        : this.teams.filter((team) => team.manager?.id === this.me.id);

      const groups = teams.map((team) => ({
        id: team.id,
        name: team.name,
        people: team.members,
      }));

      if (this.isAdmin) groups.push({ id: EVERYONE, name: "Everyone", people: this.directory });
      return groups;
    },

    group() {
      return this.groups.find((g) => String(g.id) === String(this.groupId)) || this.groups[0];
    },

    // Team members, without yourself (you have the dashed "you" card)
    people() {
      return (this.group?.people ?? []).filter((person) => person.id !== this.me.id);
    },

    selected() {
      if (this.selectedId === this.me.id) return this.me;
      return this.people.find((person) => person.id === this.selectedId) || null;
    },

    selectedStatus() {
      return this.statusOf(this.selectedId);
    },

    onClockSummary() {
      const total = this.people.length;
      const inNow = this.people.filter((person) => this.statusOf(person.id).clockIn).length;

      if (total === 0) return "No one here yet";
      if (inNow === 0) return "nobody on the clock right now";
      return `${inNow} of ${total} on the clock right now`;
    },

    liveTimer() {
      return formatTimer(this.now - new Date(this.selectedStatus.since));
    },
  },

  async mounted() {
    await this.load();

    this.ticker = setInterval(() => {
      this.now = Date.now();
    }, 1000);

    this.poller = setInterval(() => this.loadStatuses(), STATUS_REFRESH_MS);
  },

  beforeUnmount() {
    clearInterval(this.ticker);
    clearInterval(this.poller);
  },

  methods: {
    statusOf(id) {
      return this.statuses[id] || { clockIn: false, since: null, lastOut: null, todayHours: 0 };
    },

    async load() {
      this.error = "";

      try {
        const [teams, users] = await Promise.all([
          api.get("/teams"),
          this.isAdmin ? api.get("/users") : null,
        ]);

        this.teams = teams.data.data ?? [];
        this.directory = users?.data.data ?? [];
      } catch (error) {
        this.error = errorMessage(error, "Could not load your team.");
        return;
      } finally {
        this.loaded = true;
      }

      // Restore the selection from the URL (?team=&user=) when it is still valid
      const { team, user } = this.$route.query;
      this.groupId = this.groups.some((g) => String(g.id) === team) ? team : this.groups[0]?.id ?? null;

      const userId = Number(user);
      this.selectedId =
        userId === this.me.id || this.people.some((p) => p.id === userId)
          ? userId
          : this.people[0]?.id ?? this.me.id;

      this.syncQuery();
      await this.loadStatuses();
    },

    selectGroup(id) {
      this.groupId = id;
      this.selectedId = this.people[0]?.id ?? this.me.id;
      this.syncQuery();
      this.loadStatuses();
    },

    selectPerson(id) {
      this.selectedId = id;
      this.workingTimes = [];
      this.syncQuery();
    },

    syncQuery() {
      this.$router.replace({ query: { team: String(this.group?.id ?? ""), user: String(this.selectedId) } });
    },

    // Clock state and today's hours for every person card (and you).
    async loadStatuses() {
      const ids = [...this.people.map((p) => p.id), this.me.id];
      const results = await Promise.all(ids.map((id) => this.fetchStatus(id)));

      this.statuses = Object.fromEntries(ids.map((id, i) => [id, results[i]]));
    },

    async fetchStatus(id) {
      const today = startOfDay(new Date());
      const tomorrow = addDays(today, 1);

      try {
        const attendance = await getAttendance(id);
        const clockIn = attendance.clockIn;
        const since = attendance.startDateTime;
        const completed = attendance.workingTimes;
        const all = clockIn ? [...completed, { start: since, end: new Date() }] : completed;
        const todayKey = toDateKey(today);
        const endsToday = completed.map((w) => new Date(w.end)).filter((d) => toDateKey(d) === todayKey);

        return {
          clockIn,
          since,
          lastOut: !clockIn && endsToday.length ? new Date(Math.max(...endsToday)) : null,
          todayHours: hoursByDay(all, today, tomorrow)[todayKey] ?? 0,
        };
      } catch {
        return { clockIn: false, since: null, lastOut: null, todayHours: 0 };
      }
    },

    // After adding / editing a punch for the selected person
    async refreshSelected(reloadList = true) {
      if (reloadList) await this.$refs.workingTimes?.getWorkingTimes();
      this.$refs.hoursReport?.load();
      this.statuses = { ...this.statuses, [this.selectedId]: await this.fetchStatus(this.selectedId) };
    },
  },
};
</script>

<style scoped>
.team-title {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 4px 14px;
}

.team-title p {
  margin: 0;
  color: var(--tm-ink-muted);
}

.title-skeleton {
  height: 160px;
}

.empty {
  color: var(--tm-ink-muted);
  font-weight: 600;
  text-align: center;
}

.people {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(300px, 100%), 1fr));
  gap: var(--tm-gap);
}

.no-people {
  align-self: center;
  margin: 0;
}

.top-row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--tm-gap-section);
  align-items: stretch;
}

.week {
  flex: 2 1 520px;
}

.add-punch {
  flex: 1 1 340px;
  display: flex;
  flex-direction: column;
}

.add-punch > * {
  flex: 1;
}

.live-box {
  display: flex;
  flex-direction: column;
  padding: 10px 16px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-input);
  background: var(--tm-live-soft);
}

.live-label {
  color: var(--tm-live-text);
  font-size: 14px;
  font-weight: 700;
}

.live-timer {
  font-size: 28px;
  font-variant-numeric: tabular-nums;
}

.punches-card {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap);
}
</style>
