<template>
  <div class="app">
    <header class="topbar">
      <div class="topbar-content">
        <div>
          <h1>Time Manager</h1>
          <p>Manage employee working time and attendance.</p>
        </div>

        <div class="user-selector">
          <label>Active user</label>

          <select v-model.number="selectedUserId">
            <option value="" disabled>
              Select a user
            </option>

            <option
              v-for="user in users"
              :key="user.id"
              :value="user.id"
            >
              {{ user.username }} — {{ user.email }}
            </option>
          </select>
        </div>
      </div>
    </header>

    <main class="dashboard">
      <!-- USER MANAGEMENT -->
      <section class="card">
        <div class="card-header">
          <div>
            <h2>User Management</h2>
            <p>Create users or manage the currently selected account.</p>
          </div>
        </div>

        <User
          :user-id="selectedUserId"
          :user="selectedUser"
          @user-created="handleUserCreated"
          @user-updated="refreshUsers"
          @user-deleted="handleUserDeleted"
        />
      </section>

      <!-- NO USER -->
      <section
        v-if="!selectedUserId"
        class="empty-user"
      >
        <div class="empty-icon">👤</div>

        <h2>Select a user</h2>

        <p>
          Choose a user from the menu above to manage their working
          time, clock status and statistics.
        </p>
      </section>

      <!-- DASHBOARD FOR SELECTED USER -->
      <template v-else>
        <section class="profile-banner">
          <div>
            <span class="profile-label">Active account</span>

            <h2>{{ selectedUser?.username }}</h2>

            <p>{{ selectedUser?.email }}</p>
          </div>

          <div class="profile-id">
            User #{{ selectedUserId }}
          </div>
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
            />
          </section>

          <!-- ADD / EDIT WORKING TIME -->
          <section class="card">
            <div class="card-header">
              <div>
                <h2>
                  {{
                    selectedWorkingTime
                      ? "Edit Working Time"
                      : "Add Working Time"
                  }}
                </h2>

                <p>
                  {{
                    selectedWorkingTime
                      ? "Update or delete the selected entry."
                      : "Add a new working-time entry."
                  }}
                </p>
              </div>
            </div>

            <WorkingTime
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
              <p>
                All recorded working times for
                {{ selectedUser?.username }}.
              </p>
            </div>
          </div>

          <WorkingTimes
  ref="workingTimes"
  :user-id="selectedUserId"
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
    </main>
  </div>
</template>

<script>
import axios from "axios";

import User from "./components/user.vue";
import WorkingTimes from "./components/WorkingTimes.vue";
import WorkingTime from "./components/WorkingTime.vue";
import ClockManager from "./components/ClockManager.vue";
import ChartManager from "./components/ChartManager.vue";

export default {
  components: {
    User,
    WorkingTimes,
    WorkingTime,
    ClockManager,
    ChartManager,
  },

  data() {
    return {
      users: [],
      selectedUserId: "",
      selectedWorkingTime: null,
    };
  },

  computed: {
    selectedUser() {
      return (
        this.users.find(
          (user) => user.id === this.selectedUserId
        ) || null
      );
    },
  },

  watch: {
    selectedUserId() {
      this.selectedWorkingTime = null;
    },
  },

  mounted() {
    this.refreshUsers();
  },

  methods: {
    async refreshUsers(preferredUserId = null) {
      try {
        const response = await axios.get(
          "http://57.130.61.152:4000/api/users"
        );

        const data =
          response.data.data ?? response.data;

        this.users =
          Array.isArray(data) ? data : [];

        if (preferredUserId) {
          this.selectedUserId = preferredUserId;
          return;
        }

        if (
          this.selectedUserId &&
          !this.users.some(
            (user) => user.id === this.selectedUserId
          )
        ) {
          this.selectedUserId = "";
        }
      } catch (error) {
        console.error("LOAD USERS ERROR:", error);
      }
    },

    async handleUserCreated(userId) {
      await this.refreshUsers(userId);
    },

    async handleUserDeleted() {
      this.selectedUserId = "";
      this.selectedWorkingTime = null;

      await this.refreshUsers();
    },

    async handleWorkingTimeSaved() {
      this.selectedWorkingTime = null;

      if (this.$refs.workingTimes) {
        await this.$refs.workingTimes.getWorkingTimes();
      }

      if (this.$refs.chartManager) {
        await this.$refs.chartManager.getWorkingTimes();
      }
    },
  },
};
</script>

<style>
* {
  box-sizing: border-box;
}

html,
body,
#app {
  margin: 0;
  min-height: 100%;
}

body {
  font-family:
    Inter,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;

  background: #f4f6fa;
  color: #1f2937;
}

button,
input,
select {
  font: inherit;
}

/* HEADER */

.topbar {
  background: #111827;
  color: white;
  padding: 26px 20px;
}

.topbar-content {
  max-width: 1150px;
  margin: auto;

  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 30px;
}

.topbar h1 {
  margin: 0;
  color: white;
  font-size: 28px;
}

.topbar p {
  margin: 6px 0 0;
  color: #9ca3af;
}

.user-selector {
  display: flex;
  flex-direction: column;
  gap: 6px;

  min-width: 300px;
}

.user-selector label {
  color: #d1d5db;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.user-selector select {
  width: 100%;
  padding: 11px 13px;

  border: 1px solid #374151;
  border-radius: 9px;

  background: #1f2937;
  color: white;

  outline: none;
}

/* MAIN */

.dashboard {
  max-width: 1150px;
  margin: auto;

  padding: 30px 18px 60px;

  display: grid;
  gap: 22px;
}

.card {
  background: white;

  border: 1px solid #e5e7eb;
  border-radius: 16px;

  padding: 24px;

  box-shadow:
    0 1px 2px rgba(0, 0, 0, 0.03),
    0 8px 25px rgba(0, 0, 0, 0.04);
}

.card-header {
  margin-bottom: 20px;
  padding-bottom: 16px;

  border-bottom: 1px solid #eef0f3;
}

.card-header h2 {
  margin: 0;
  font-size: 18px;
  color: #111827;
}

.card-header p {
  margin: 5px 0 0;
  color: #6b7280;
  font-size: 13px;
}

/* ACTIVE PROFILE */

.profile-banner {
  background: #eef2ff;

  border: 1px solid #dfe3ff;
  border-radius: 16px;

  padding: 22px 26px;

  display: flex;
  justify-content: space-between;
  align-items: center;
}

.profile-label {
  display: block;

  margin-bottom: 5px;

  color: #6366f1;
  font-size: 12px;
  font-weight: 700;

  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.profile-banner h2 {
  margin: 0;
  color: #1f2937;
}

.profile-banner p {
  margin: 5px 0 0;
  color: #6b7280;
}

.profile-id {
  background: white;

  padding: 9px 14px;

  border-radius: 8px;

  color: #4f46e5;
  font-weight: 600;
}

/* TWO COLUMN */

.two-column {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 22px;
}

/* EMPTY USER */

.empty-user {
  text-align: center;

  padding: 70px 20px;

  border: 2px dashed #d1d5db;
  border-radius: 16px;

  background: white;
}

.empty-icon {
  font-size: 40px;
}

.empty-user h2 {
  margin-bottom: 8px;
}

.empty-user p {
  max-width: 450px;
  margin: auto;
  color: #6b7280;
}

/* GLOBAL FORM ELEMENTS */

input {
  width: 100%;

  padding: 10px 12px;

  border: 1px solid #d1d5db;
  border-radius: 9px;

  background: white;
  color: #111827;

  outline: none;
}

input:focus {
  border-color: #6366f1;

  box-shadow:
    0 0 0 3px rgba(99, 102, 241, 0.12);
}

button {
  border: none;
  border-radius: 9px;

  padding: 10px 15px;

  background: #4f46e5;
  color: white;

  font-weight: 600;

  cursor: pointer;

  transition: 0.15s;
}

button:hover {
  background: #4338ca;
}

button.secondary {
  background: #eef2ff;
  color: #4338ca;
}

button.secondary:hover {
  background: #e0e7ff;
}

button.danger {
  background: #fee2e2;
  color: #b91c1c;
}

button.danger:hover {
  background: #fecaca;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* RESPONSIVE */

@media (max-width: 800px) {
  .topbar-content {
    flex-direction: column;
    align-items: stretch;
  }

  .user-selector {
    min-width: 0;
  }

  .two-column {
    grid-template-columns: 1fr;
  }

  .profile-banner {
    align-items: flex-start;
    gap: 20px;
    flex-direction: column;
  }
}
</style>