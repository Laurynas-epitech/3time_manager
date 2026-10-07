<template>
  <nav
    class="tabbar"
    aria-label="Main"
  >
    <router-link
      v-for="tab in tabs"
      :key="tab.to"
      :to="tab.to"
      class="tab"
      @click="tap"
    >
      <svg
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <path :d="tab.icon" />
      </svg>
      <span>{{ tab.label }}</span>
    </router-link>
  </nav>
</template>

<script>
import auth from "../auth";
import { vibrate } from "../native";

const ICONS = {
  clock: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 2a8 8 0 1 1 0 16 8 8 0 0 1 0-16zm-1 3v6l5 3 1-1.6-4-2.4V7h-2z",
  history: "M4 5h16v2H4V5zm0 6h16v2H4v-2zm0 6h10v2H4v-2z",
  team: "M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zm8 0a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM2 19c0-3 3-5 6-5s6 2 6 5v1H2v-1zm12.5-4.6c.5-.2 1-.4 1.5-.4 3 0 6 2 6 5v1h-6v-1c0-1.8-.6-3.3-1.5-4.6z",
  profile: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm-8 8c0-3.3 3.6-6 8-6s8 2.7 8 6v1H4v-1z",
};

export default {
  name: "TabBar",

  computed: {
    tabs() {
      const tabs = [
        { to: "/", label: "Clock", icon: ICONS.clock },
        { to: "/history", label: "History", icon: ICONS.history },
      ];

      if (auth.hasRole("manager", "admin")) {
        tabs.push({ to: "/teams", label: "Team", icon: ICONS.team });
      }

      tabs.push({ to: "/profile", label: "Profile", icon: ICONS.profile });

      return tabs;
    },
  },

  methods: {
    tap() {
      vibrate("light");
    },
  },
};
</script>

<style scoped>
.tabbar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20;
  display: flex;
  background: #ffffff;
  border-top: 1px solid #e5e7eb;
  padding-bottom: env(safe-area-inset-bottom, 0px);
}

.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 8px 4px 10px;
  min-height: 58px;
  color: #6b7280;
  text-decoration: none;
  font-size: 12px;
  font-weight: 600;
  -webkit-tap-highlight-color: transparent;
}

.tab svg {
  width: 24px;
  height: 24px;
  fill: currentColor;
}

.tab.router-link-exact-active {
  color: #4f46e5;
}
</style>
