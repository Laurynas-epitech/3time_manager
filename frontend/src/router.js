import { createRouter, createWebHistory } from "vue-router";

import auth from "./auth";
import { setUnauthorizedHandler } from "./api";

import LoginView from "./views/LoginView.vue";
import RegisterView from "./views/RegisterView.vue";
import DashboardView from "./views/DashboardView.vue";
import ProfileView from "./views/ProfileView.vue";
import TeamsView from "./views/TeamsView.vue";
import MyTeamView from "./views/MyTeamView.vue";
import AdminView from "./views/AdminView.vue";

const routes = [
  { path: "/login", name: "login", component: LoginView, meta: { guestOnly: true } },
  { path: "/register", name: "register", component: RegisterView, meta: { guestOnly: true } },

  { path: "/", name: "dashboard", component: DashboardView, meta: { requiresAuth: true } },
  { path: "/profile", name: "profile", component: ProfileView, meta: { requiresAuth: true } },
  {
    path: "/team",
    name: "my-team",
    component: MyTeamView,
    meta: { requiresAuth: true, roles: ["manager", "admin"] },
  },
  {
    path: "/teams",
    name: "teams",
    component: TeamsView,
    // Everyone can see their teams; only managers/admins get the edit controls.
    meta: { requiresAuth: true },
  },
  {
    path: "/admin",
    name: "admin",
    component: AdminView,
    meta: { requiresAuth: true, roles: ["admin"] },
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
  if (auth.isDemo()) return;
  auth.clearSession();

  if (router.currentRoute.value.meta.requiresAuth) {
    router.push({ name: "login" });
  }
});

export default router;
