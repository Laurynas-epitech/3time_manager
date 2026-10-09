<template>
  <!-- "Today": your own card. Managers and admins see other people on /team. -->
  <div
    v-if="me"
    class="view"
  >
    <!-- HERO + THIS WEEK -->
    <div class="top-row">
      <ClockManager
        class="hero"
        :user-id="me.id"
        :user-name="me.username"
        :team-names="teamNames"
        :teams-loaded="teamsLoaded"
        :working-times="workingTimes"
        @status="clockStatus = $event"
        @clock-changed="refresh"
      />

      <WeekCard
        class="week"
        :working-times="workingTimes"
        :live-since="clockStatus.clockIn ? clockStatus.startDateTime : null"
      />
    </div>

    <!-- DAILY / WEEKLY HOURS OVER A PERIOD -->
    <HoursReport
      ref="hoursReport"
      :user-id="me.id"
    />

    <!-- PUNCHES (read-only here) -->
    <section
      class="punches-section"
      aria-labelledby="punches-title"
    >
      <h2
        id="punches-title"
        class="tm-h2"
      >
        Recent punches
      </h2>

      <WorkingTimes
        ref="workingTimes"
        :user-id="me.id"
        @loaded="workingTimes = $event"
      />
    </section>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";

import WorkingTimes from "../components/WorkingTimes.vue";
import ClockManager from "../components/ClockManager.vue";
import HoursReport from "../components/HoursReport.vue";
import WeekCard from "../components/WeekCard.vue";

export default {
  name: "DashboardView",

  components: { WorkingTimes, ClockManager, HoursReport, WeekCard },

  data() {
    return {
      teams: [],
      teamsLoaded: false,
      // Shared by the hero, the week card and the punch list
      workingTimes: [],
      clockStatus: { clockIn: false, startDateTime: null },
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    // Teams you manage or belong to (admins receive every team).
    teamNames() {
      const id = this.me?.id;

      return this.teams
        .filter((team) => team.manager?.id === id || team.members.some((m) => m.id === id))
        .map((team) => team.name);
    },
  },

  mounted() {
    this.loadTeams();
  },

  methods: {
    async loadTeams() {
      try {
        const { data } = await api.get("/teams");
        this.teams = data.data ?? [];
      } catch (error) {
        console.error("LOAD TEAMS ERROR:", error);
        this.teams = [];
      } finally {
        this.teamsLoaded = true;
      }
    },

    async refresh() {
      await this.$refs.workingTimes?.getWorkingTimes();
      await this.$refs.hoursReport?.load();
    },
  },
};
</script>

<style scoped>
.top-row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--tm-gap-section);
  align-items: stretch;
}

.hero {
  flex: 1 1 340px;
}

.week {
  flex: 2 1 520px;
}

.punches-section {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap);
}
</style>
