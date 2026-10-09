<template>
  <div class="view">
    <header class="page-title">
      <h1 class="tm-h1">Teams</h1>
      <p>
        {{
          isEmployee
            ? "The teams you belong to. Only managers and admins can change them."
            : "One manager per team. People can be on more than one."
        }}
      </p>
    </header>

    <!-- CREATE TEAM (admin) -->
    <section
      v-if="isAdmin"
      class="card"
    >
      <div class="card-header">
        <div>
          <h2>Create a team</h2>
          <p>A team has one manager. Employees can be in several teams.</p>
        </div>
      </div>

      <p
        v-if="createError"
        class="error-msg"
      >
        {{ createError }}
      </p>

      <form @submit.prevent="createTeam">
        <div class="form-grid">
          <div class="field">
            <label for="t-name">Team name</label>
            <input
              id="t-name"
              v-model.trim="newTeam.name"
              required
            />
          </div>

          <div class="field">
            <label for="t-manager">Manager</label>
            <select
              id="t-manager"
              v-model="newTeam.manager_id"
            >
              <option :value="null">No manager yet</option>
              <option
                v-for="u in managerCandidates"
                :key="u.id"
                :value="u.id"
              >
                {{ u.username }} ({{ u.role }})
              </option>
            </select>
          </div>
        </div>

        <button type="submit">Create team</button>
      </form>
    </section>

    <p
      v-if="error"
      class="error-msg"
    >
      {{ error }}
    </p>

    <section
      v-if="teams.length === 0"
      class="card empty"
    >
      {{
        isAdmin
          ? "No teams yet."
          : isEmployee
            ? "You're not in a team yet. An admin can add you."
            : "You don't manage or belong to any team yet. Ask an admin to assign you one."
      }}
    </section>

    <!-- TEAMS -->
    <section
      v-for="team in teams"
      :key="team.id"
      class="card"
    >
      <div class="card-header team-header">
        <div>
          <h2>{{ team.name }}</h2>
          <p>
            Manager:
            <strong>{{ team.manager ? team.manager.username : "none" }}</strong>
            · {{ team.members.length }} member{{ team.members.length === 1 ? "" : "s" }}
          </p>
        </div>

        <div
          v-if="isAdmin"
          class="actions"
        >
          <select
            :value="team.manager ? team.manager.id : ''"
            aria-label="Change manager"
            @change="changeManager(team, $event.target.value)"
          >
            <option value="">No manager</option>
            <option
              v-for="u in managerCandidates"
              :key="u.id"
              :value="u.id"
            >
              {{ u.username }}
            </option>
          </select>

          <button
            class="danger"
            @click="deleteTeam(team)"
          >
            Delete team
          </button>
        </div>
      </div>

      <div class="table-wrap">
        <table
          v-if="team.members.length"
          class="data"
        >
          <thead>
            <tr>
              <th>Member</th>
              <th>Email</th>
              <th>Role</th>
              <th v-if="canManage(team)">
                <span class="tm-sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="m in team.members"
              :key="m.id"
            >
              <td>
                {{ m.username }}
                <span
                  v-if="m.id === me?.id"
                  class="you"
                >
                  (you)
                </span>
              </td>
              <td>{{ m.email }}</td>
              <td>
                <span
                  class="role-badge"
                  :class="m.role"
                >
                  {{ m.role }}
                </span>
              </td>
              <td v-if="canManage(team)">
                <button
                  class="secondary"
                  @click="removeMember(team, m)"
                >
                  Remove
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div
        v-if="canManage(team)"
        class="add-member"
      >
        <select
          v-model="toAdd[team.id]"
          :aria-label="`Add a member to ${team.name}`"
        >
          <option
            :value="undefined"
            disabled
          >
            Add a member...
          </option>
          <option
            v-for="u in nonMembers(team)"
            :key="u.id"
            :value="u.id"
          >
            {{ u.username }} ({{ u.email }})
          </option>
        </select>

        <button
          :disabled="!toAdd[team.id]"
          @click="addMember(team)"
        >
          Add
        </button>
      </div>
    </section>
  </div>
</template>

<script>
import api, { errorMessage } from "../api";
import auth from "../auth";

export default {
  name: "TeamsView",

  data() {
    return {
      teams: [],
      directory: [],
      newTeam: { name: "", manager_id: null },
      toAdd: {},
      error: "",
      createError: "",
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    isAdmin() {
      return auth.hasRole("admin");
    },

    isEmployee() {
      return auth.hasRole("employee");
    },

    managerCandidates() {
      return this.directory.filter((u) => u.role === "manager" || u.role === "admin");
    },
  },

  mounted() {
    this.load();
  },

  methods: {
    async load() {
      this.error = "";

      try {
        // Employees only read their teams: no user directory needed.
        const [teams, users] = await Promise.all([
          api.get("/teams"),
          this.isEmployee ? null : api.get("/users", { params: { scope: "all" } }),
        ]);
        this.teams = teams.data.data;
        this.directory = users?.data.data ?? [];
      } catch (error) {
        this.error = errorMessage(error, "Could not load teams.");
      }
    },

    // Same rule as the backend: admins, or the team's own manager.
    canManage(team) {
      return this.isAdmin || (!!this.me && team.manager?.id === this.me.id);
    },

    nonMembers(team) {
      const ids = new Set(team.members.map((m) => m.id));
      return this.directory.filter((u) => !ids.has(u.id));
    },

    replaceTeam(updated) {
      this.teams = this.teams.map((t) => (t.id === updated.id ? updated : t));
    },

    async createTeam() {
      this.createError = "";

      try {
        await api.post("/teams", { team: this.newTeam });
        this.newTeam = { name: "", manager_id: null };
        await this.load();
      } catch (error) {
        this.createError = errorMessage(error, "Could not create the team.");
      }
    },

    async changeManager(team, managerId) {
      try {
        const { data } = await api.put(`/teams/${team.id}`, {
          team: { manager_id: managerId || null },
        });
        this.replaceTeam(data.data);
      } catch (error) {
        this.error = errorMessage(error, "Could not change the manager.");
        await this.load();
      }
    },

    async deleteTeam(team) {
      if (!window.confirm(`Delete team ${team.name}?`)) return;

      try {
        await api.delete(`/teams/${team.id}`);
        this.teams = this.teams.filter((t) => t.id !== team.id);
      } catch (error) {
        this.error = errorMessage(error, "Could not delete the team.");
      }
    },

    async addMember(team) {
      try {
        const { data } = await api.post(`/teams/${team.id}/members/${this.toAdd[team.id]}`);
        this.replaceTeam(data.data);
        this.toAdd[team.id] = undefined;
      } catch (error) {
        this.error = errorMessage(error, "Could not add the member.");
      }
    },

    async removeMember(team, member) {
      try {
        const { data } = await api.delete(`/teams/${team.id}/members/${member.id}`);
        this.replaceTeam(data.data);
      } catch (error) {
        this.error = errorMessage(error, "Could not remove the member.");
      }
    },
  },
};
</script>

<style scoped>
.team-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  flex-wrap: wrap;
}

.add-member {
  display: flex;
  gap: 10px;
  margin-top: 16px;
}

.add-member select {
  flex: 1;
  max-width: 420px;
}

.page-title p {
  margin: 8px 0 0;
  color: var(--tm-ink-muted);
}

.you {
  color: var(--tm-ink-muted);
}

.empty {
  color: var(--tm-ink-muted);
}
</style>
