<template>
  <div class="view">
    <!-- CREATE USER -->
    <section class="card">
      <div class="card-header">
        <div>
          <h2>Create a user</h2>
          <p>Admins can create accounts with any role.</p>
        </div>
      </div>

      <p
        v-if="createError"
        class="error-msg"
      >
        {{ createError }}
      </p>

      <form @submit.prevent="createUser">
        <div class="form-grid">
          <div class="field">
            <label for="a-username">Username</label>
            <input
              id="a-username"
              v-model.trim="form.username"
              required
            />
          </div>

          <div class="field">
            <label for="a-email">Email</label>
            <input
              id="a-email"
              v-model.trim="form.email"
              type="email"
              required
            />
          </div>

          <div class="field">
            <label for="a-password">Temporary password</label>
            <input
              id="a-password"
              v-model="form.password"
              type="password"
              minlength="6"
              autocomplete="new-password"
              required
            />
          </div>

          <div class="field">
            <label for="a-role">Role</label>
            <select
              id="a-role"
              v-model="form.role"
            >
              <option
                v-for="role in roles"
                :key="role.id"
                :value="role.name"
              >
                {{ role.name }}
              </option>
            </select>
          </div>
        </div>

        <button type="submit">Create user</button>
      </form>
    </section>

    <!-- USERS + ROLE PROMOTION / DEMOTION -->
    <section class="card">
      <div class="card-header">
        <div>
          <h2>Users and roles</h2>
          <p>Promote or demote users by changing their role.</p>
        </div>
      </div>

      <p
        v-if="error"
        class="error-msg"
      >
        {{ error }}
      </p>

      <div class="table-wrap">
        <table class="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>User</th>
              <th>Email</th>
              <th>Role</th>
              <th></th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="u in users"
              :key="u.id"
            >
              <td>#{{ u.id }}</td>
              <td>{{ u.username }}</td>
              <td>{{ u.email }}</td>
              <td>
                <select
                  :value="u.role"
                  :disabled="u.id === me?.id"
                  :aria-label="`Role of ${u.username}`"
                  @change="changeRole(u, $event.target.value)"
                >
                  <option
                    v-for="role in roles"
                    :key="role.id"
                    :value="role.name"
                  >
                    {{ role.name }}
                  </option>
                </select>
              </td>
              <td>
                <button
                  v-if="u.id !== me?.id"
                  class="danger"
                  @click="deleteUser(u)"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>

<script>
import api, { errorMessage } from "../api";
import auth from "../auth";

const emptyForm = () => ({ username: "", email: "", password: "", role: "employee" });

export default {
  name: "AdminView",

  data() {
    return {
      users: [],
      roles: [],
      form: emptyForm(),
      error: "",
      createError: "",
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },
  },

  mounted() {
    this.load();
  },

  methods: {
    async load() {
      try {
        const [users, roles] = await Promise.all([api.get("/users"), api.get("/roles")]);
        this.users = users.data.data;
        this.roles = roles.data.data;
      } catch (error) {
        this.error = errorMessage(error, "Could not load users.");
      }
    },

    async createUser() {
      this.createError = "";

      try {
        await api.post("/users", { user: this.form });
        this.form = emptyForm();
        await this.load();
      } catch (error) {
        this.createError = errorMessage(error, "Could not create the user.");
      }
    },

    async changeRole(user, role) {
      this.error = "";

      try {
        const { data } = await api.put(`/users/${user.id}/role`, { role });
        user.role = data.data.role;
      } catch (error) {
        this.error = errorMessage(error, "Could not change the role.");
        await this.load();
      }
    },

    async deleteUser(user) {
      if (!window.confirm(`Delete ${user.username}?`)) return;

      try {
        await api.delete(`/users/${user.id}`);
        this.users = this.users.filter((u) => u.id !== user.id);
      } catch (error) {
        this.error = errorMessage(error, "Could not delete the user.");
      }
    },
  },
};
</script>
