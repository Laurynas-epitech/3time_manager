<template>
  <div class="history-screen">
    <!-- Managers and admins can look at their team -->
    <section
      v-if="users.length > 1"
      class="card picker"
    >
      <label for="m-user-pick">Employee</label>
      <select
        id="m-user-pick"
        v-model.number="selectedUserId"
      >
        <option
          v-for="u in users"
          :key="u.id"
          :value="u.id"
        >
          {{ u.username }}{{ u.id === me.id ? " (you)" : "" }}
        </option>
      </select>
    </section>

    <!-- Add / edit (managers and admins) -->
    <section
      v-if="canEdit"
      class="card"
    >
      <button
        v-if="!formOpen"
        class="add-btn"
        @click="formOpen = true"
      >
        + Add working time
      </button>

      <template v-else>
        <h3 class="form-title">
          {{ editing ? "Edit working time" : "New working time" }}
        </h3>

        <WorkingTime
          :user-id="selectedUserId"
          :working-time="editing"
          @saved="afterSave"
          @deleted="afterSave"
          @cancel-edit="closeForm"
        />

        <button
          v-if="!editing"
          class="secondary close-btn"
          @click="closeForm"
        >
          Cancel
        </button>
      </template>
    </section>

    <section class="card">
      <WorkingTimes
        ref="list"
        :user-id="selectedUserId"
        :can-edit="canEdit"
        @edit-working-time="edit"
      />
    </section>
  </div>
</template>

<script>
import auth from "../../auth";
import { cachedGet } from "../../offline";
import WorkingTimes from "../../components/WorkingTimes.vue";
import WorkingTime from "../../components/WorkingTime.vue";

export default {
  name: "HistoryView",

  components: { WorkingTimes, WorkingTime },

  data() {
    return {
      users: [],
      selectedUserId: auth.state.user?.id ?? null,
      formOpen: false,
      editing: null,
    };
  },

  computed: {
    me() {
      return auth.state.user;
    },

    canEdit() {
      return auth.hasRole("manager", "admin");
    },
  },

  watch: {
    selectedUserId() {
      this.closeForm();
    },
  },

  mounted() {
    this.loadUsers();
  },

  methods: {
    async loadUsers() {
      try {
        const { data } = await cachedGet("/users");
        this.users = data.data ?? [];
      } catch {
        this.users = [];
      }
    },

    edit(workingTime) {
      this.editing = workingTime;
      this.formOpen = true;
      window.scrollTo({ top: 0, behavior: "smooth" });
    },

    closeForm() {
      this.formOpen = false;
      this.editing = null;
    },

    async afterSave() {
      this.closeForm();
      await this.$refs.list?.getWorkingTimes();
    },
  },
};
</script>

<style scoped>
.history-screen {
  display: grid;
  gap: 14px;
}

.picker {
  display: grid;
  gap: 6px;
}

.picker label {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
}

.add-btn {
  width: 100%;
}

.form-title {
  margin: 0 0 12px;
  font-size: 17px;
}

.close-btn {
  width: 100%;
  margin-top: 10px;
}

/* Stack the history rows on narrow screens */
.history-screen :deep(.working-row) {
  grid-template-columns: 1fr auto;
}
</style>
