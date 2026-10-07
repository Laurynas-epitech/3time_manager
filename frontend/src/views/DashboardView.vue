<template>
  <div class="view">
    <!-- WHOSE DATA (only if there is more than one visible user) -->
    <section
      v-if="users.length > 1"
      class="card picker"
    >
      <div class="field">
        <label for="user-pick">Viewing</label>

        <select
          id="user-pick"
          v-model.number="selectedUserId"
        >
          <option
            v-for="u in users"
            :key="u.id"
            :value="u.id"
          >
            {{ u.username }} ({{ u.email }}){{ u.id === me?.id ? " · you" : "" }}
          </option>
        </select>
      </div>

      <p class="hint">
        {{
          isAdmin
            ? "As an admin you can see every user."
            : "You can see the members of the teams you manage."
        }}
      </p>
    </section>

    <template v-if="selectedUser">
      <section class="profile-banner">
        <div>
          <span class="profile-label">
            {{ isSelf ? "Your account" : "Selected employee" }}
          </span>

          <h2>{{ selectedUser.username }}</h2>

          <p>{{ selectedUser.email }}</p>
        </div>

        <span
          class="role-badge"
          :class="selectedUser.role"
        >
          {{ selectedUser.role }}
        </span>
      </section>

      <div class="two-column">
        <!-- CLOCK -->
        <section class="card">
          <div class="card-header">
            <div>
              <h2>Clock</h2>
              <p>Current attendance status.</p>
            </div>
          </div>

          <ClockManager
            :user-id="selectedUserId"
            :can-clock="canClock"
          />
        </section>

        <!-- ADD / EDIT WORKING TIME (managers and admins) -->
        <section class="card">
          <div class="card-header">
            <div>
              <h2>
                {{ selectedWorkingTime ? "Edit Working Time" : "Add Working Time" }}
              </h2>

              <p>
                {{
                  canEditWorkingTimes
                    ? selectedWorkingTime
                      ? "Update or delete the selected entry."
                      : "Add a new working-time entry."
                    : "Only managers and admins can edit working times."
                }}
              </p>
            </div>
          </div>

          <WorkingTime
            v-if="canEditWorkingTimes"
            :user-id="selectedUserId"
            :working-time="selectedWorkingTime"
            @saved="handleWorkingTimeSaved"
            @deleted="handleWorkingTimeSaved"
            @cancel-edit="selectedWorkingTime = null"
          />
        </section>
      </div>

      <!-- HISTORY -->
      <section class="card">
        <div class="card-header">
          <div>
            <h2>Working Time History</h2>
            <p>All recorded working times for {{ selectedUser.username }}.</p>
          </div>
        </div>

        <WorkingTimes
          ref="workingTimes"
          :user-id="selectedUserId"
          :can-edit="canEditWorkingTimes"
          @edit-working-time="selectedWorkingTime = $event"
        />
      </section>

      <!-- CHARTS -->
      <section class="card">
        <div class="card-header">
          <div>
            <h2>Statistics</h2>
            <p>Overview of recorded hours.</p>
          </div>
        </div>

        <ChartManager
          ref="chartManager"
          :user-id="selectedUserId"
        />
      </section>
    </template>
  </div>
</template>

<script>
import { cachedGet } from "../offline";
import auth from "../auth";

import WorkingTimes from "../components/WorkingTimes.vue";
import WorkingTime from "../components/WorkingTime.vue";
import ClockManager from "../components/ClockManager.vue";
import ChartManager from "../components/ChartManager.vue";

export default {
  name: "DashboardView",

  components: { WorkingTimes, WorkingTime, ClockManager, ChartManager },

  data() {
    return {
      users: [],
      selectedUserId: auth.state.user?.id ?? null,
      selectedWorkingTime: null,
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    isAdmin() {
      return auth.hasRole("admin");
    },

    isSelf() {
      return !!this.me && this.selectedUserId === this.me.id;
    },

    selectedUser() {
      if (!this.me) return null;
      if (this.isSelf) return this.me;
      return this.users.find((u) => u.id === this.selectedUserId) || null;
    },

    // Mirrors the backend rules (TimeManagerWeb.Authorization).
    canClock() {
      return this.isAdmin || this.isSelf;
    },

    canEditWorkingTimes() {
      return auth.hasRole("manager", "admin");
    },
  },

  watch: {
    selectedUserId() {
      this.selectedWorkingTime = null;
    },
  },

  mounted() {
    this.loadUsers();
  },

  methods: {
    async loadUsers() {
      try {
        const { data } = await cachedGet("/users");
        this.users = data.data ?? [];
      } catch (error) {
        console.error("LOAD USERS ERROR:", error);
        this.users = [];
      }
    },

    async handleWorkingTimeSaved() {
      this.selectedWorkingTime = null;
      await this.$refs.workingTimes?.getWorkingTimes();
      await this.$refs.chartManager?.getWorkingTimes();
    },
  },
};
</script>

<style scoped>
.picker {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 20px;
  flex-wrap: wrap;
}

.picker .field {
  min-width: 320px;
}

.hint {
  margin: 0;
  color: #6b7280;
  font-size: 13px;
}
</style>
