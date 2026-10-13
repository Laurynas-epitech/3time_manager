<template>
  <section class="card view" aria-labelledby="team-report-title">
    <h2 id="team-report-title">Team averages</h2>
    <p>Completed recorded hours per current member, including members with no hours. Overlapping records are summed.</p>
    <form class="filters" @submit.prevent="load">
      <label>From<input v-model="from" type="date" required /></label>
      <label>Through<input v-model="to" type="date" required /></label>
      <label>Timezone<select v-model="timezone"><option v-for="zone in zones" :key="zone">{{ zone }}</option></select></label>
      <button :disabled="loading">Show averages</button>
    </form>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="loading" role="status">Loading team report…</p>
    <template v-else-if="report">
      <p v-if="!report.member_count">No members</p>
      <template v-else>
        <p>{{ report.member_count }} members · {{ report.timezone }} · completed sessions only</p>
        <div class="table-scroll" v-for="kind in ['daily', 'weekly']" :key="kind">
          <table><caption>{{ kind === 'daily' ? 'Daily' : 'Weekly' }} hours per member</caption>
            <thead><tr><th scope="col">Period</th><th scope="col">Team total (h)</th><th scope="col">Average per member (h)</th></tr></thead>
            <tbody><tr v-for="row in report[kind]" :key="row.date || row.start">
              <th scope="row">{{ row.date || `${row.start} – ${row.end}${row.partial ? ' (partial week)' : ''}` }}</th>
              <td>{{ row.total_hours.toFixed(2) }}</td><td>{{ row.average_hours.toFixed(2) }}</td>
            </tr></tbody>
          </table>
        </div>
      </template>
    </template>
  </section>
</template>
<script>
import api, { errorMessage } from '../api';
import { toDateKey, startOfWeek } from '../time';
export default {
  props: { teamId: { type: [Number, String], required: true } },
  data() {
    const zone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    return { from: toDateKey(startOfWeek(new Date())), to: toDateKey(new Date()),
      timezone: zone, zones: [...new Set([zone, 'UTC', 'Europe/Paris'])], report: null, error: '', loading: false, request: 0 };
  },
  watch: { teamId: { immediate: true, handler() { this.load(); } } },
  methods: {
    async load() {
      const request = ++this.request;
      this.report = null; this.error = ''; this.loading = true;
      try {
        const response = await api.get(`/teams/${this.teamId}/report`, { params: { start: this.from, end: this.to, timezone: this.timezone } });
        if (request === this.request) this.report = response.data.data;
      } catch (error) { if (request === this.request) this.error = errorMessage(error, 'Could not load team averages. Choose an ordered period of at most 366 days.'); }
      finally { if (request === this.request) this.loading = false; }
    },
  },
};
</script>
<style scoped>
.filters { display:flex; flex-wrap:wrap; gap:16px; align-items:end; }
.filters label { flex:1 1 160px; }
.table-scroll { overflow:auto; }
table { width:100%; } caption { text-align:left; font-weight:700; } th,td { text-align:left; padding:8px; }
</style>
