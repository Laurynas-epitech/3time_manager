<template>
  <div class="working-form">
    <div class="field">
      <label>Start</label>

      <input
        v-model="start"
        type="datetime-local"
      />
    </div>

    <div class="field">
      <label>End</label>

      <input
        v-model="end"
        type="datetime-local"
      />
    </div>

    <div class="actions">
      <button
        v-if="!workingTime"
        @click="createWorkingTime"
        :disabled="!start || !end"
      >
        Add Working Time
      </button>

      <template v-else>
        <button
          @click="updateWorkingTime"
          :disabled="!start || !end"
        >
          Save Changes
        </button>

        <button
          class="secondary"
          @click="cancelEdit"
        >
          Cancel
        </button>

        <button
          class="danger"
          @click="deleteWorkingTime"
        >
          Delete
        </button>
      </template>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "WorkingTime",

  props: {
  userId: {
    type: Number,
    required: true,
  },

  workingTime: {
    type: Object,
    default: null,
  },
},

emits: [
  "saved",
  "deleted",
  "cancel-edit",
],

data() {
  return {
    start: "",
    end: "",
  };
},

watch: {
  workingTime: {
    immediate: true,

    handler(value) {
      if (value) {
        this.start =
          this.toDateTimeLocal(
            value.start
          );

        this.end =
          this.toDateTimeLocal(
            value.end
          );
      } else {
        this.start = "";
        this.end = "";
      }
    },
  },
},

  methods: {
    toDateTimeLocal(value) {
      if (!value) return "";

      const date = new Date(value);

      const offset =
        date.getTimezoneOffset();

      const localDate =
        new Date(
          date.getTime() -
            offset * 60 * 1000
        );

      return localDate
        .toISOString()
        .slice(0, 16);
    },

    getPayload() {
      return {
        working_time: {
          start: new Date(
            this.start
          ).toISOString(),

          end: new Date(
            this.end
          ).toISOString(),
        },
      };
    },

   async createWorkingTime() {
  if (!this.userId) return;

  try {
    await axios.post(
      `http://localhost:4000/api/workingTime/${this.userId}`,
      this.getPayload()
    );

    this.start = "";
    this.end = "";

    this.$emit("saved");
  } catch (error) {
    console.error(
      "CREATE WORKING TIME ERROR:",
      error
    );
  }
},

    async updateWorkingTime() {
  if (!this.workingTime) return;

  try {
    await axios.put(
      `http://localhost:4000/api/workingTime/${this.userId}/${this.workingTime.id}`,
      this.getPayload()
    );

    this.start = "";
    this.end = "";

    this.$emit("saved");
  } catch (error) {
    console.error(
      "UPDATE WORKING TIME ERROR:",
      error
    );
  }
},

    async deleteWorkingTime() {
  if (!this.workingTime) return;

  const confirmed =
    window.confirm(
      "Delete this working-time entry?"
    );

  if (!confirmed) return;

  try {
    await axios.delete(
      `http://localhost:4000/api/workingTime/${this.userId}/${this.workingTime.id}`
    );

    this.start = "";
    this.end = "";

    this.$emit("deleted");
  } catch (error) {
    console.error(
      "DELETE WORKING TIME ERROR:",
      error
    );
  }
},

    cancelEdit() {
      this.start = "";
      this.end = "";

      this.$emit("cancel-edit");
    },
  },
};
</script>

<style scoped>
.working-form {
  display: grid;
  gap: 14px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

label {
  color: #6b7280;
  font-size: 12px;
  font-weight: 600;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;

  margin-top: 5px;
}
</style>