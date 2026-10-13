<template>
  <div class="view">
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="loading" role="status">Loading user…</p>
    <template v-else-if="target">
      <h1 v-if="mode !== 'clock'">{{ target.username }} · {{ heading }}</h1>
      <nav class="links" aria-label="Attendance reports">
        <router-link :to="`/workingTimes/${userId}`">Working times</router-link>
        <router-link :to="`/chartManager/${userId}`">Charts</router-link>
        <router-link v-if="canEdit" :to="`/workingTime/${userId}`">Add working time</router-link>
        <router-link v-if="userId === me.id" :to="`/clock/${userId}`">Clock</router-link>
      </nav>
      <WorkingTimes v-if="mode === 'times'" :user-id="userId" :can-edit="canEdit" />
      <WorkingTime v-else-if="mode === 'edit'" :user-id="userId" :working-time="record" @saved="afterSave" @deleted="afterSave" @cancel-edit="afterSave" />
      <ClockManager v-else-if="mode === 'clock'" :user-id="userId" :user-name="target.username" :working-times="clockTimes" @clock-changed="refreshClockTimes" />
      <ChartManager v-else-if="mode === 'charts'" :user-id="userId" />
    </template>
  </div>
</template>
<script>
import auth from '../auth';
import api, { errorMessage } from '../api';
import WorkingTimes from '../components/WorkingTimes.vue';
import WorkingTime from '../components/WorkingTime.vue';
import ClockManager from '../components/ClockManager.vue';
import ChartManager from '../components/ChartManager.vue';
import { getAttendance } from '../services/attendance';
export default {
  components: { WorkingTimes, WorkingTime, ClockManager, ChartManager },
  props: { mode: { type: String, required: true } },
  data() { return { target: null, record: null, clockTimes: [], loading: false, error: '', request: 0 }; },
  computed: {
    me() { return auth.state.user; }, userId() { return Number(this.$route.params.userid); },
    canEdit() { return ['manager', 'admin'].includes(this.me.role); },
    heading() { return { times: 'Working times', edit: 'Working time', clock: 'Clock', charts: 'Charts' }[this.mode]; },
  },
  watch: { '$route.fullPath': { immediate: true, handler() { this.load(); } } },
  methods: {
    async refreshClockTimes() {
      try { this.clockTimes = (await getAttendance(this.userId, { refresh: false })).workingTimes; }
      catch (error) { this.error = errorMessage(error, 'Could not refresh attendance.'); }
    },
    async load() {
      const request = ++this.request;
      this.target = null; this.record = null; this.error = ''; this.loading = true;
      try {
        if (!/^[1-9]\d*$/.test(this.$route.params.userid) || !Number.isSafeInteger(this.userId)) throw new Error('Invalid user ID.');
        if (this.mode === 'clock' && this.userId !== this.me.id) throw new Error('You can only clock your own attendance.');
        if (this.mode === 'edit' && !this.canEdit) throw new Error('Only managers and administrators can edit working times.');
        const target = this.userId === this.me.id ? this.me : (await api.get(`/users/${this.userId}`)).data.data;
        if (this.mode === 'clock') {
          const attendance = await getAttendance(this.userId);
          if (request === this.request) this.clockTimes = attendance.workingTimes;
        }
        let record = null;
        const id = this.$route.params.workingtimeid;
        if (id) {
          if (!/^[1-9]\d*$/.test(id)) throw new Error('Invalid working time ID.');
          record = (await api.get(`/workingtime/${this.userId}/${id}`)).data.data;
        }
        if (request === this.request) { this.target = target; this.record = record; }
      } catch (error) { if (request === this.request) this.error = errorMessage(error, error.message || 'Could not access attendance.'); }
      finally { if (request === this.request) this.loading = false; }
    },
    afterSave() { this.$router.push(`/workingTimes/${this.userId}`); },
  },
};
</script>
<style scoped>.links { display:flex; flex-wrap:wrap; gap:16px; } .links a { min-height:44px; display:flex; align-items:center; }</style>
