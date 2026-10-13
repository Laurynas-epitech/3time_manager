<template>
  <section class="card view">
    <h2>Working hours charts</h2>
    <p>Completed recorded hours · {{ timezone }}. Overlapping records are summed.</p>
    <form class="filters" @submit.prevent="getWorkingTimes">
      <label>From<input v-model="from" type="date" required /></label>
      <label>Through<input v-model="to" type="date" required /></label>
      <button :disabled="loading">Update charts</button>
    </form>
    <label for="chart-graph">Graph</label>
    <select id="chart-graph" v-model="graph"><option value="all">All three</option><option value="bar">Daily bars</option><option value="line">Weekly line</option><option value="pie">Weekday pie</option></select>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="loading" role="status">Loading charts…</p>
    <template v-else>
      <p v-if="!total">No recorded hours in this period.</p>
      <div v-if="total" class="charts">
        <div v-if="graph === 'all' || graph === 'bar'" class="chart"><h3>Daily hours (h)</h3><Bar :data="dailyData" :options="options" aria-label="Daily hours; values in the table below" /></div>
        <div v-if="graph === 'all' || graph === 'line'" class="chart"><h3>Weekly hours (h)</h3><Line :data="weeklyData" :options="options" aria-label="Weekly hours; values in the table below" /></div>
        <div v-if="graph === 'all' || graph === 'pie'" class="chart"><h3>Hours by weekday (h)</h3><Pie :data="weekdayData" :options="pieOptions" aria-label="Weekday hours; values in the table below" /></div>
      </div>
      <div v-for="[name, rows] in [['Daily', days], ['Weekly', weeks], ['Weekday', weekdays]]" :key="name" class="table-scroll">
        <table><caption>{{ name }} recorded hours · total {{ total.toFixed(2) }} h</caption><thead><tr><th scope="col">Period</th><th scope="col">Hours</th></tr></thead><tbody><tr v-for="row in rows" :key="row.label"><th scope="row">{{ row.label }}</th><td>{{ row.hours.toFixed(2) }}</td></tr></tbody></table>
      </div>
    </template>
  </section>
</template>
<script>
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, LineElement, PointElement, ArcElement, CategoryScale, LinearScale } from 'chart.js';
import { Bar, Line, Pie } from 'vue-chartjs';
import { getAttendance, attendanceState } from '../services/attendance';
import auth from '../auth';
import { getDemoAttendance } from '../services/demoAttendance';
import { errorMessage } from '../api';
import { toDateKey, startOfWeek } from '../time';
import { reportBuckets } from '../services/reporting';
ChartJS.register(Title, Tooltip, Legend, BarElement, LineElement, PointElement, ArcElement, CategoryScale, LinearScale);
const colors = ['#4f46e5', '#0f766e', '#c2410c', '#a21caf', '#0369a1', '#a16207', '#be123c'];
const dataset = (rows) => ({ labels: rows.map(row => row.label), datasets: [{ label: 'Recorded hours (h)', data: rows.map(row => row.hours), backgroundColor: colors, borderColor: '#4f46e5', borderWidth: 2 }] });
export default {
  components: { Bar, Line, Pie },
  props: { userId: { type: Number, required: true } },
  data() { return { from: toDateKey(startOfWeek(new Date())), to: toDateKey(new Date()), graph: 'all', workingTimes: [], loading: false, error: '', request: 0, timezone: Intl.DateTimeFormat().resolvedOptions().timeZone }; },
  computed: {
    revision() { return attendanceState.revision; },
    buckets() { try { return reportBuckets(this.workingTimes, this.from, this.to); } catch { return { daily: [], weekly: [], weekday: [] }; } },
    days() { return this.buckets.daily; }, weeks() { return this.buckets.weekly; }, weekdays() { return this.buckets.weekday; },
    total() { return this.days.reduce((sum, row) => sum + row.hours, 0); },
    dailyData() { return dataset(this.days); }, weeklyData() { return dataset(this.weeks); }, weekdayData() { return dataset(this.weekdays); },
    options() { return { responsive: true, maintainAspectRatio: false, scales: { y: { beginAtZero: true, title: { display: true, text: 'Hours' } } }, plugins: { legend: { display: false } } }; },
    pieOptions() { return { responsive: true, maintainAspectRatio: false }; },
  },
  watch: { userId: { immediate: true, handler() { this.getWorkingTimes(); } }, revision() { this.getWorkingTimes(false); } },
  methods: {
    async getWorkingTimes(refresh = true) {
      const request = ++this.request;
      this.workingTimes = []; this.error = '';
      try { reportBuckets([], this.from, this.to); }
      catch (error) { this.error = error.message; this.loading = false; return; }
      this.loading = true;
      try {
        const attendance = auth.isDemo() ? await getDemoAttendance(this.userId) : await getAttendance(this.userId, { refresh: refresh !== false });
        if (request === this.request) this.workingTimes = attendance.workingTimes;
      } catch (error) { if (request === this.request) this.error = errorMessage(error, 'Could not load charts.'); }
      finally { if (request === this.request) this.loading = false; }
    },
  },
};
</script>
<style scoped>
.filters { display:flex; flex-wrap:wrap; gap:16px; align-items:end; } .filters label { flex:1 1 160px; }
.charts { display:grid; grid-template-columns:repeat(auto-fit,minmax(min(300px,100%),1fr)); gap:24px; }
.chart { height:320px; padding-bottom:48px; min-width:0; } .table-scroll { overflow:auto; }
table { width:100%; } caption { text-align:left; font-weight:700; } th,td { padding:8px; text-align:left; }
</style>
