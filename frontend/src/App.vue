<template>
  <div class="app">
    <AppHeader
      :user="user"
      @logout="logout"
    />

    <main class="page">
      <section v-if="!demoMode && (user || sync.error)" class="sync-status" role="status" aria-live="polite">
        <p v-if="sync.syncing">Synchronising attendance: {{ sync.completed }} / {{ sync.total }}.</p>
        <p v-else-if="!user">Sign in to synchronise your saved attendance.</p>
        <p v-else-if="!sync.online">Offline — {{ sync.pending }} attendance action(s) saved on this device.</p>
        <p v-else-if="sync.pending">{{ sync.pending }} attendance action(s) waiting to synchronise.</p>
        <p v-else>All attendance changes saved.</p>
        <p v-if="user && sync.offlineReady">App downloaded for offline use.</p>
        <p v-if="sync.error" role="alert">{{ sync.error }}</p>
        <button v-if="user && !sync.syncing" class="secondary" @click="retrySync">Synchronise now</button>
      </section>
      <router-view />
    </main>

    <AppToast />
  </div>
</template>

<script>
import auth from "./auth";
import { attendanceState, synchronizeAttendance } from "./services/attendance";
import AppHeader from "./components/AppHeader.vue";
import AppToast from "./components/AppToast.vue";

export default {
  components: { AppHeader, AppToast },

  computed: {
    sync() { return attendanceState; },
    demoMode() { return auth.isDemo(); },
    user() {
      return auth.state.user;
    },
  },

  methods: {
    retrySync() { void synchronizeAttendance(); },
    async logout() {
      await auth.logout();
      this.$router.push({ name: "login" });
    },
  },
};
</script>

<style>
.sync-status { padding: 12px 16px; margin-bottom: 16px; border: var(--tm-border); border-radius: var(--tm-radius-card); background: var(--tm-surface); }
.sync-status p { margin: 4px 0; }
/* Global "Punch Card" base styles (tokens live in styles/tokens.css).
   The generic classes below (.card, .field, .error-msg, ...) keep the screens
   that are not rebuilt yet consistent with the new look. */

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
  font-size: var(--tm-fs-body);
  line-height: 1.45;
}

h1,
h2,
h3 {
  font-family: var(--tm-font-display);
  letter-spacing: -0.02em;
}

button,
input,
select {
  font: inherit;
  color: inherit;
}

/* MAIN */

.page {
  max-width: var(--tm-max-width);
  margin: 0 auto;
  padding: 12px clamp(16px, 3vw, 32px) 64px;
}

.view {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap-section);
}

.card {
  background: var(--tm-surface);
  border: var(--tm-border);
  border-radius: var(--tm-radius-card);
  box-shadow: var(--tm-shadow);
  padding: var(--tm-pad-card);
}

.card-header {
  margin-bottom: 20px;
}

.card-header h2 {
  margin: 0;
  font-size: var(--tm-fs-h2);
  font-weight: 800;
}

.card-header p {
  margin: 6px 0 0;
  color: var(--tm-ink-muted);
}

/* FORM ELEMENTS */

input:not([type="radio"]):not([type="checkbox"]),
select {
  width: 100%;
  min-height: 48px;
  padding: 0 14px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-input);
  background: #fff;
  font-weight: 500;
}

input:focus-visible,
select:focus-visible,
button:focus-visible,
summary:focus-visible {
  outline: 3px solid var(--tm-primary);
  outline-offset: 2px;
}

/* Default button: dark pill. Variants only change colours, so the .tm-btn
   classes from tokens.css keep working on top of it. */
button {
  min-height: var(--tm-hit);
  padding: 0 20px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-pill);
  background: var(--tm-ink);
  color: var(--tm-ground);
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.1s;
}

button:hover:not(:disabled) {
  transform: translate(-1px, -1px);
}

button.secondary {
  background: transparent;
  color: var(--tm-ink);
}

button.danger {
  background: transparent;
  border-color: var(--tm-danger);
  color: var(--tm-danger);
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field label {
  font-size: 14px;
  font-weight: 700;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--tm-gap);
  margin-bottom: 18px;
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

/* MESSAGES */

.error-msg {
  margin: 0 0 14px;
  color: var(--tm-danger);
  font-size: 14px;
  font-weight: 600;
}

.success-msg {
  margin: 0 0 14px;
  color: var(--tm-live-text);
  font-size: 14px;
  font-weight: 600;
}

.hint {
  color: var(--tm-ink-muted);
}

/* ROLE BADGE (legacy class name, same look as .tm-role) */

.role-badge {
  display: inline-block;
  align-self: flex-start;
  padding: 4px 10px;
  border-radius: var(--tm-radius-pill);
  font-size: var(--tm-fs-small);
  font-weight: 700;
  background: var(--tm-primary-soft);
  color: var(--tm-primary-text);
}

.role-badge.manager {
  background: var(--tm-accent-soft);
  color: var(--tm-accent-text);
}

.role-badge.admin {
  background: var(--tm-ink);
  color: var(--tm-ground);
}

/* TABLES */

table.data {
  width: 100%;
  border-collapse: collapse;
}

table.data th,
table.data td {
  text-align: left;
  padding: 12px 8px;
  border-bottom: 2px dashed var(--tm-divider);
  vertical-align: middle;
}

table.data th {
  font-size: 14px;
  font-weight: 700;
}

.table-wrap {
  overflow-x: auto;
}

/* LOADING SKELETON */

.skeleton {
  background: var(--tm-sunken);
  border-radius: var(--tm-radius-tile);
  animation: skeleton-pulse 1.2s ease-in-out infinite;
}

@keyframes skeleton-pulse {
  50% {
    opacity: 0.55;
  }
}

@media (prefers-reduced-motion: reduce) {
  .skeleton {
    animation: none;
  }

  button {
    transition: none;
  }
}

@media (max-width: 650px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}

/* Room for the fixed bottom tab bar */
@media (max-width: 640px) {
  .page {
    padding-bottom: 110px;
  }
}
</style>
