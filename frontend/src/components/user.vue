<template>
  <div class="user-manager">
    <div class="user-section">
      <h3>Create New User</h3>

      <div class="form-grid">
        <div class="field">
          <label>Username</label>

          <input
            v-model="newUsername"
            type="text"
            placeholder="John Smith"
          />
        </div>

        <div class="field">
          <label>Email</label>

          <input
            v-model="newEmail"
            type="email"
            placeholder="john@example.com"
          />
        </div>
      </div>

      <button
        @click="createUser"
        :disabled="!newUsername || !newEmail"
      >
        Create User
      </button>
    </div>

    <div
      v-if="userId && user"
      class="selected-user"
    >
      <h3>Selected User</h3>

      <div class="form-grid">
        <div class="field">
          <label>Username</label>

          <input
            v-model="editUsername"
            type="text"
          />
        </div>

        <div class="field">
          <label>Email</label>

          <input
            v-model="editEmail"
            type="email"
          />
        </div>
      </div>

      <div class="actions">
        <button @click="updateUser">
          Save Changes
        </button>

        <button
          class="danger"
          @click="deleteUser"
        >
          Delete User
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "User",

  props: {
    userId: {
      type: [Number, String],
      default: "",
    },

    user: {
      type: Object,
      default: null,
    },
  },

  emits: [
    "user-created",
    "user-updated",
    "user-deleted",
  ],

  data() {
    return {
      newUsername: "",
      newEmail: "",

      editUsername: "",
      editEmail: "",
    };
  },

  watch: {
    user: {
      immediate: true,

      handler(newUser) {
        if (newUser) {
          this.editUsername =
            newUser.username || "";

          this.editEmail =
            newUser.email || "";
        } else {
          this.editUsername = "";
          this.editEmail = "";
        }
      },
    },
  },

  methods: {
    async createUser() {
      try {
        const response = await axios.post(
          "http://57.130.61.152:4000/api/users",
          {
            user: {
              username: this.newUsername,
              email: this.newEmail,
            },
          }
        );

        const createdUser =
          response.data.data ?? response.data;

        this.newUsername = "";
        this.newEmail = "";

        this.$emit(
          "user-created",
          createdUser.id
        );
      } catch (error) {
        console.error(
          "CREATE USER ERROR:",
          error
        );
      }
    },

    async getUser() {
  if (!this.userId) {
    return null;
  }

  try {
    const response = await axios.get(
      `http://57.130.61.152:4000/api/users/${this.userId}`
    );

    const data =
      response.data.data ?? response.data;

    this.editUsername =
      data.username || "";

    this.editEmail =
      data.email || "";

    return data;
  } catch (error) {
    console.error(
      "GET USER ERROR:",
      error
    );

    return null;
  }
},

    async updateUser() {
      if (!this.userId) return;

      try {
        await axios.put(
          `http://57.130.61.152:4000/api/users/${this.userId}`,
          {
            user: {
              username: this.editUsername,
              email: this.editEmail,
            },
          }
        );

        this.$emit("user-updated");
      } catch (error) {
        console.error(
          "UPDATE USER ERROR:",
          error
        );
      }
    },

    async deleteUser() {
      if (!this.userId) return;

      const confirmed = window.confirm(
        "Delete this user?"
      );

      if (!confirmed) return;

      try {
        await axios.delete(
          `http://57.130.61.152:4000/api/users/${this.userId}`
        );

        this.$emit("user-deleted");
      } catch (error) {
        console.error(
          "DELETE USER ERROR:",
          error
        );
      }
    },
  },
};
</script>

<style scoped>
.user-manager {
  display: grid;
  gap: 28px;
}

.user-section,
.selected-user {
  padding: 18px;

  border: 1px solid #e5e7eb;
  border-radius: 12px;

  background: #fafafa;
}

h3 {
  margin: 0 0 16px;
  color: #1f2937;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;

  gap: 14px;

  margin-bottom: 15px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

label {
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
}

.actions {
  display: flex;
  gap: 10px;
}

@media (max-width: 650px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>