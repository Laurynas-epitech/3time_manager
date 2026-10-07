<template>
  <ClockView v-if="isMobile" />
  <DashboardView v-else />
</template>

<script>
import { isMobile } from "../layout";
import DashboardView from "./DashboardView.vue";
import ClockView from "./mobile/ClockView.vue";

// "/" is the dashboard on desktop and the clock screen on mobile
// (the subject says dashboards don't need a mobile version).
export default {
  name: "HomeView",

  components: { DashboardView, ClockView },

  computed: {
    isMobile() {
      return isMobile.value;
    },
  },
};
</script>
