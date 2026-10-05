<template>
  <div class="auth-page">
    <section class="card auth-card">
      <div class="card-header">
        <div>
          <h2>Log in</h2>
          <p>Use your work email and password.</p>
        </div>
      </div>

      <p
        v-if="error"
        class="error-msg"
      >
        {{ error }}
      </p>

      <form
        class="auth-form"
        @submit.prevent="submit"
      >
        <div class="field">
          <label for="login-email">Email</label>
          <input
            id="login-email"
            v-model.trim="email"
            type="email"
            autocomplete="email"
            required
          />
        </div>

        <div class="field">
          <label for="login-password">Password</label>
          <input
            id="login-password"
            v-model="password"
            type="password"
            autocomplete="current-password"
            required
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
        >
          {{ loading ? "Logging in..." : "Log in" }}
        </button>
      </form>

      <p class="switch">
        No account yet?
        <router-link to="/register">Create one</router-link>
      </p>
    </section>
  </div>
</template>

<script>
import auth from "../auth";
import { errorMessage } from "../api";

export default {
  name: "LoginView",

  data() {
    return { email: "", password: "", error: "", loading: false };
  },

  methods: {
    async submit() {
      this.error = "";
      this.loading = true;

      try {
        await auth.login(this.email, this.password);
        this.$router.push(this.$route.query.redirect || "/");
      } catch (error) {
        this.error = errorMessage(error, "Could not log in.");
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<style>
.auth-page {
  display: grid;
  place-items: start center;
  padding-top: 30px;
}

.auth-card {
  width: 100%;
  max-width: 420px;
}

.auth-form {
  display: grid;
  gap: 14px;
}

.auth-form button {
  margin-top: 6px;
}

.switch {
  margin: 18px 0 0;
  font-size: 14px;
  color: #6b7280;
}

.switch a {
  color: #4f46e5;
  font-weight: 600;
}
</style>
