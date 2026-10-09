<template>
  <header class="app-header">
    <router-link
      to="/"
      class="logo"
      aria-label="timemanager, go to Today"
    >
      <span
        class="logo-mark"
        aria-hidden="true"
      >
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2.6"
          stroke-linecap="round"
        >
          <path d="M12 6v6l4 2" />
        </svg>
      </span>
      timemanager
    </router-link>

    <template v-if="user">
      <!-- Desktop: pill group. Under 640px the same items move to the bottom tab bar. -->
      <nav
        class="nav-pills"
        aria-label="Main"
      >
        <router-link
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-pill"
          :class="{ active: isActive(item) }"
        >
          {{ item.label }}
        </router-link>
      </nav>

      <div class="account">
        <span class="account-name">{{ user.username }}</span>
        <span
          class="tm-role"
          :class="`tm-role--${user.role}`"
        >
          {{ user.role }}
        </span>
        <button
          type="button"
          class="tm-btn logout"
          @click="$emit('logout')"
        >
          Log out
        </button>
      </div>

      <!-- Mobile: avatar button with a small menu -->
      <div class="account-mobile">
        <button
          type="button"
          class="avatar"
          :aria-label="`Account menu for ${user.username}`"
          aria-haspopup="true"
          :aria-expanded="menuOpen"
          @click="menuOpen = !menuOpen"
        >
          {{ initial }}
        </button>

        <div
          v-if="menuOpen"
          class="account-menu"
        >
          <span class="account-name">{{ user.username }}</span>
          <span
            class="tm-role"
            :class="`tm-role--${user.role}`"
          >
            {{ user.role }}
          </span>
          <button
            type="button"
            class="tm-btn"
            @click="logoutFromMenu"
          >
            Log out
          </button>
        </div>
      </div>

      <nav
        class="tab-bar"
        aria-label="Main"
      >
        <router-link
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="tab"
          :class="{ active: isActive(item) }"
        >
          {{ item.label }}
        </router-link>
      </nav>
    </template>
  </header>
</template>

<script>
export default {
  name: "AppHeader",

  props: {
    user: {
      type: Object,
      default: null,
    },
  },

  emits: ["logout"],

  data() {
    return { menuOpen: false };
  },

  computed: {
    // Items per role (DESIGN.md 2), plus a read-only Teams page for employees.
    // Admins (general manager) also get the team view, to see everyone's hours.
    navItems() {
      const role = this.user?.role;
      const items = [{ to: "/", label: "Today" }];

      if (role === "manager") items.push({ to: "/team", label: "My team" });
      if (role === "admin") items.push({ to: "/team", label: "Dashboards" });
      items.push({ to: "/teams", label: "Teams" });
      if (role === "admin") items.push({ to: "/admin", label: "People" });

      items.push({ to: "/profile", label: "Profile" });
      return items;
    },

    initial() {
      return (this.user?.username || "?").charAt(0).toUpperCase();
    },
  },

  watch: {
    $route() {
      this.menuOpen = false;
    },
  },

  methods: {
    // Path match, ignoring the query (/team?user=3 is still "My team")
    isActive(item) {
      return this.$route.path === item.to;
    },

    logoutFromMenu() {
      this.menuOpen = false;
      this.$emit("logout");
    },
  },
};
</script>

<style scoped>
.app-header {
  max-width: var(--tm-max-width);
  margin: 0 auto;
  box-sizing: border-box;
  padding: 20px clamp(16px, 3vw, 32px);
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--tm-ink);
  text-decoration: none;
  font-family: var(--tm-font-display);
  font-size: 24px;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.logo-mark {
  width: 32px;
  height: 32px;
  box-sizing: border-box;
  border-radius: 50%;
  background: var(--tm-accent);
  border: var(--tm-border);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--tm-ink);
}

.nav-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  padding: 4px;
  border: var(--tm-border);
  border-radius: var(--tm-radius-pill);
  background: var(--tm-surface);
}

.nav-pill {
  display: flex;
  align-items: center;
  min-height: var(--tm-hit);
  padding: 0 20px;
  border-radius: var(--tm-radius-pill);
  color: var(--tm-ink);
  text-decoration: none;
  font-weight: 500;
}

.nav-pill.active {
  background: var(--tm-ink);
  color: var(--tm-ground);
  font-weight: 700;
}

.nav-pill:focus-visible,
.tab:focus-visible,
.logo:focus-visible,
.avatar:focus-visible {
  outline: 3px solid var(--tm-primary);
  outline-offset: 2px;
}

.account {
  display: flex;
  align-items: center;
  gap: 10px;
}

.account-name {
  font-weight: 600;
}

.logout {
  min-height: var(--tm-hit);
  padding: 0 16px;
  font-weight: 600;
}

.account-mobile,
.tab-bar {
  display: none;
}

@media (max-width: 640px) {
  .nav-pills,
  .account {
    display: none;
  }

  .account-mobile {
    display: block;
    position: relative;
  }

  .avatar {
    width: var(--tm-hit);
    height: var(--tm-hit);
    border: var(--tm-border);
    border-radius: 50%;
    background: var(--tm-sunken);
    color: var(--tm-ink);
    font-family: var(--tm-font-display);
    font-size: 18px;
    font-weight: 800;
    cursor: pointer;
  }

  .account-menu {
    position: absolute;
    right: 0;
    top: calc(100% + 8px);
    z-index: 20;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
    min-width: 180px;
    padding: 16px;
    background: var(--tm-surface);
    border: var(--tm-border);
    border-radius: var(--tm-radius-tile);
    box-shadow: var(--tm-shadow-sm);
  }

  .tab-bar {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 10;
    display: flex;
    justify-content: space-around;
    gap: 4px;
    padding: 8px 8px calc(8px + env(safe-area-inset-bottom));
    background: var(--tm-surface);
    border-top: var(--tm-border);
  }

  .tab {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: var(--tm-hit);
    border-radius: var(--tm-radius-pill);
    color: var(--tm-ink);
    text-decoration: none;
    font-weight: 600;
    font-size: 14px;
  }

  .tab.active {
    background: var(--tm-ink);
    color: var(--tm-ground);
  }
}
</style>
