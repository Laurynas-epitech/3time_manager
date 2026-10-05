<template>
  <div
    v-if="me"
    class="view"
  >
    <section class="card">
      <div class="card-header">
        <div>
          <h2>Profile</h2>
          <p>Update your account details. Leave the password empty to keep it.</p>
        </div>
      </div>

      <p
        v-if="error"
        class="error-msg"
      >
        {{ error }}
      </p>

      <p
        v-if="success"
        class="success-msg"
      >
        {{ success }}
      </p>

      <form @submit.prevent="save">
        <div class="form-grid">
          <div class="field">
            <label for="p-username">Username</label>
            <input
              id="p-username"
              v-model.trim="username"
              type="text"
              required
            />
          </div>

          <div class="field">
            <label for="p-email">Email</label>
            <input
              id="p-email"
              v-model.trim="email"
              type="email"
              required
            />
          </div>

          <div class="field">
            <label for="p-password">New password</label>
            <input
              id="p-password"
              v-model="password"
              type="password"
              autocomplete="new-password"
              minlength="6"
            />
          </div>

          <div class="field">
            <label>Role</label>
            <span
              class="role-badge"
              :class="me.role"
            >
              {{ me.role }}
            </span>
          </div>
        </div>

        <div class="actions">
          <button
            type="submit"
            :disabled="saving"
          >
            Save changes
          </button>

          <button
            type="button"
            class="danger"
            @click="remove"
          >
            Delete my account
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<script>
import api, { errorMessage } from "../api";
import auth from "../auth";

export default {
  name: "ProfileView",

  data() {
    return {
      username: auth.state.user.username,
      email: auth.state.user.email,
      password: "",
      error: "",
      success: "",
      saving: false,
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },
  },

  methods: {
    async save() {
      this.error = "";
      this.success = "";
      this.saving = true;

      const user = { username: this.username, email: this.email };
      if (this.password) user.password = this.password;

      try {
        const { data } = await api.put(`/users/${this.me.id}`, { user });
        auth.updateUser(data.data);
        this.password = "";
        this.success = "Profile updated.";
      } catch (error) {
        this.error = errorMessage(error, "Could not update the profile.");
      } finally {
        this.saving = false;
      }
    },

    async remove() {
      if (!window.confirm("Delete your account? This can't be undone.")) return;

      try {
        await api.delete(`/users/${this.me.id}`);
        await auth.logout();
        this.$router.push({ name: "login" });
      } catch (error) {
        this.error = errorMessage(error, "Could not delete the account.");
      }
    },
  },
};
</script>
