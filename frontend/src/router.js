import { createRouter, createWebHistory } from "vue-router";

import auth from "./auth";
import { setUnauthorizedHandler } from "./api";

import LoginView from "./views/LoginView.vue";
import RegisterView from "./views/RegisterView.vue";
import HomeView from "./views/HomeView.vue";
import HistoryView from "./views/mobile/HistoryView.vue";
import ProfileView from "./views/ProfileView.vue";
import TeamsView from "./views/TeamsView.vue";
import AdminView from "./views/AdminView.vue";

const routes = [
  { path: "/login", name: "login", component: LoginView, meta: { guestOnly: true, title: "Log in" } },
  {
    path: "/register",
    name: "register",
    component: RegisterView,
    meta: { guestOnly: true, title: "Create account" },
  },

  // Desktop: dashboard. Mobile: the clock screen (dashboards are desktop-only).
  { path: "/", name: "dashboard", component: HomeView, meta: { requiresAuth: true, title: "Clock" } },
  {
    path: "/history",
    name: "history",
    component: HistoryView,
    meta: { requiresAuth: true, title: "History" },
  },
  {
    path: "/profile",
    name: "profile",
    component: ProfileView,
    meta: { requiresAuth: true, title: "Profile" },
  },
  {
    path: "/teams",
    name: "teams",
    component: TeamsView,
    meta: { requiresAuth: true, roles: ["manager", "admin"], title: "Team" },
  },
  {
    path: "/admin",
    name: "admin",
    component: AdminView,
    meta: { requiresAuth: true, roles: ["admin"], title: "Admin" },
  },

  { path: "/:pathMatch(.*)*", redirect: "/" },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach(async (to) => {
  // First navigation: try to restore the session from the cookie.
  if (!auth.state.checked) {
    await auth.fetchMe();
  }

  const loggedIn = !!auth.state.user;

  if (to.meta.requiresAuth && !loggedIn) {
    return { name: "login", query: { redirect: to.fullPath } };
  }

  if (to.meta.guestOnly && loggedIn) {
    return { name: "dashboard" };
  }

  if (to.meta.roles && !auth.hasRole(...to.meta.roles)) {
    return { name: "dashboard" };
  }

  return true;
});

// Session expired / cookie gone -> back to login.
setUnauthorizedHandler(() => {
  auth.clearSession();

  if (router.currentRoute.value.meta.requiresAuth) {
    router.push({ name: "login" });
  }
});

export default router;
