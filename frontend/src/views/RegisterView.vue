<template>
  <div class="auth-page">
    <section class="card auth-card">
      <div class="card-header">
        <div>
          <h2>Create an account</h2>
          <p>New accounts start with the employee role.</p>
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
          <label for="reg-username">Username</label>
          <input
            id="reg-username"
            v-model.trim="username"
            type="text"
            autocomplete="username"
            required
          />
        </div>

        <div class="field">
          <label for="reg-email">Email</label>
          <input
            id="reg-email"
            v-model.trim="email"
            type="email"
            autocomplete="email"
            required
          />
        </div>

        <div class="field">
          <label for="reg-password">Password (6 characters minimum)</label>
          <input
            id="reg-password"
            v-model="password"
            type="password"
            autocomplete="new-password"
            minlength="6"
            required
          />
        </div>

        <div class="field">
          <label for="reg-confirm">Confirm password</label>
          <input
            id="reg-confirm"
            v-model="confirm"
            type="password"
            autocomplete="new-password"
            required
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
        >
          {{ loading ? "Creating account..." : "Create account" }}
        </button>
      </form>

      <p class="switch">
        Already registered?
        <router-link to="/login">Log in</router-link>
      </p>
    </section>
  </div>
</template>

<script>
import auth from "../auth";
import { errorMessage } from "../api";

export default {
  name: "RegisterView",

  data() {
    return { username: "", email: "", password: "", confirm: "", error: "", loading: false };
  },

  methods: {
    async submit() {
      this.error = "";

      if (this.password !== this.confirm) {
        this.error = "Passwords don't match.";
        return;
      }

      this.loading = true;

      try {
        await auth.register({
          username: this.username,
          email: this.email,
          password: this.password,
        });
        this.$router.push("/");
      } catch (error) {
        this.error = errorMessage(error, "Could not create the account.");
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
