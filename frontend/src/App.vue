<template>
  <div class="app">
    <header class="topbar">
      <div class="topbar-content">
        <div>
          <h1>Time Manager</h1>
          <p>Manage employee working time and attendance.</p>
        </div>

        <div
          v-if="user"
          class="session"
        >
          <nav class="nav">
            <router-link to="/">Dashboard</router-link>

            <router-link
              v-if="isManagerOrAdmin"
              to="/teams"
            >
              Teams
            </router-link>

            <router-link
              v-if="isAdmin"
              to="/admin"
            >
              Admin
            </router-link>

            <router-link to="/profile">Profile</router-link>
          </nav>

          <span>
            {{ user.username }}
            <span
              class="role-badge"
              :class="user.role"
            >
              {{ user.role }}
            </span>
          </span>

          <button
            class="secondary"
            @click="logout"
          >
            Log out
          </button>
        </div>
      </div>
    </header>

    <main class="dashboard">
      <router-view />
    </main>
  </div>
</template>

<script>
import auth from "./auth";

export default {
  computed: {
    user() {
      return auth.state.user;
    },

    isAdmin() {
      return auth.hasRole("admin");
    },

    isManagerOrAdmin() {
      return auth.hasRole("manager", "admin");
    },
  },

  methods: {
    async logout() {
      await auth.logout();
      this.$router.push({ name: "login" });
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

/* Undo the Vite template defaults from style.css */
#app {
  width: 100%;
  text-align: left;
  border-inline: none;
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


.view {
  display: grid;
  gap: 22px;
}

/* NAVIGATION */

.nav {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.nav a {
  color: #d1d5db;
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
  padding: 8px 12px;
  border-radius: 8px;
}

.nav a:hover {
  background: #1f2937;
  color: white;
}

.nav a.router-link-exact-active {
  background: #312e81;
  color: white;
}

.session {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #d1d5db;
  font-size: 14px;
}

.role-badge {
  display: inline-block;
  padding: 3px 9px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  background: #e0e7ff;
  color: #3730a3;
}

.role-badge.admin {
  background: #fee2e2;
  color: #991b1b;
}

.role-badge.manager {
  background: #fef3c7;
  color: #92400e;
}

/* SHARED FORM BITS */

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field label {
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-bottom: 15px;
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.error-msg {
  margin: 0 0 14px;
  padding: 10px 12px;
  border-radius: 9px;
  background: #fee2e2;
  color: #991b1b;
  font-size: 14px;
}

.success-msg {
  margin: 0 0 14px;
  padding: 10px 12px;
  border-radius: 9px;
  background: #dcfce7;
  color: #166534;
  font-size: 14px;
}

select {
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 9px;
  background: white;
  color: #111827;
}

table.data {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

table.data th,
table.data td {
  text-align: left;
  padding: 10px 8px;
  border-bottom: 1px solid #eef0f3;
  vertical-align: middle;
}

table.data th {
  color: #6b7280;
  font-size: 12px;
  font-weight: 600;
}

.table-wrap {
  overflow-x: auto;
}

@media (max-width: 650px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
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