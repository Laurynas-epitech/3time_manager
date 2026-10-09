<template>
  <form
    class="punch-form"
    :class="{ editing: !!workingTime }"
    @submit.prevent="workingTime ? updateWorkingTime() : createWorkingTime()"
  >
    <h2
      v-if="!workingTime"
      class="tm-h2"
    >
      Add a punch{{ personName ? ` for ${personName}` : "" }}
    </h2>

    <label
      class="tm-label"
      :for="`${uid}-day`"
    >
      Day
      <input
        :id="`${uid}-day`"
        v-model="day"
        class="tm-input"
        type="date"
        required
      />
    </label>

    <div class="times">
      <label
        class="tm-label"
        :for="`${uid}-in`"
      >
        In
        <input
          :id="`${uid}-in`"
          v-model="timeIn"
          class="tm-input"
          type="time"
          required
        />
      </label>

      <label
        class="tm-label"
        :for="`${uid}-out`"
      >
        Out
        <input
          :id="`${uid}-out`"
          v-model="timeOut"
          class="tm-input"
          type="time"
          required
        />
      </label>
    </div>

    <p
      v-if="overnight"
      class="note"
    >
      Ends the next day.
    </p>

    <p
      v-if="error"
      class="error-msg"
      role="alert"
    >
      {{ error }}
    </p>

    <div class="actions">
      <button
        type="submit"
        class="tm-btn tm-btn--dark submit"
        :disabled="saving || !duration"
      >
        {{ workingTime ? "Save" : "Add" }}{{ duration ? ` ${formatHours(duration)}` : "" }}
      </button>

      <template v-if="workingTime">
        <button
          type="button"
          class="tm-btn"
          @click="cancelEdit"
        >
          Cancel
        </button>

        <button
          type="button"
          class="tm-btn delete"
          :disabled="saving"
          @click="deleteWorkingTime"
        >
          Delete
        </button>
      </template>
    </div>
  </form>
</template>

<script>
import api, { errorMessage } from "../api";
import { showToast } from "../toast";
import { addDays, formatHours, fromDateKey, toDateKey } from "../time";

const pad = (n) => String(n).padStart(2, "0");
let counter = 0;

export default {
  name: "WorkingTime",

  props: {
    userId: {
      type: Number,
      required: true,
    },

    // null: create a new punch / object: edit that punch
    workingTime: {
      type: Object,
      default: null,
    },

    personName: {
      type: String,
      default: "",
    },
  },

  emits: ["saved", "deleted", "cancel-edit"],

  data() {
    return {
      uid: `punch-${++counter}`,
      day: toDateKey(new Date()),
      timeIn: "09:00",
      timeOut: "17:00",
      error: "",
      saving: false,
    };
  },

  computed: {
    start() {
      if (!this.day || !this.timeIn) return null;
      const [h, m] = this.timeIn.split(":").map(Number);
      const date = fromDateKey(this.day);
      date.setHours(h, m, 0, 0);
      return date;
    },

    // An "Out" earlier than "In" means the shift ended after midnight
    overnight() {
      return !!this.timeIn && !!this.timeOut && this.timeOut <= this.timeIn;
    },

    end() {
      if (!this.day || !this.timeOut) return null;
      const [h, m] = this.timeOut.split(":").map(Number);
      const date = fromDateKey(this.day);
      date.setHours(h, m, 0, 0);
      return this.overnight ? addDays(date, 1) : date;
    },

    duration() {
      return this.start && this.end ? (this.end - this.start) / 3_600_000 : 0;
    },
  },

  watch: {
    workingTime: {
      immediate: true,

      handler(value) {
        this.error = "";
        if (!value) return;

        const start = new Date(value.start);
        const end = new Date(value.end);

        this.day = toDateKey(start);
        this.timeIn = `${pad(start.getHours())}:${pad(start.getMinutes())}`;
        this.timeOut = `${pad(end.getHours())}:${pad(end.getMinutes())}`;
      },
    },
  },

  methods: {
    formatHours,

    getPayload() {
      return {
        working_time: {
          start: this.start.toISOString(),
          end: this.end.toISOString(),
        },
      };
    },

    async createWorkingTime() {
      if (!this.userId || !this.duration) return;

      this.error = "";
      this.saving = true;

      try {
        await api.post(`/workingTime/${this.userId}`, this.getPayload());
        showToast(`Punch added · ${formatHours(this.duration)}`);
        this.$emit("saved");
      } catch (error) {
        console.error("CREATE WORKING TIME ERROR:", error);
        this.error = errorMessage(error, "Could not add the punch.");
      } finally {
        this.saving = false;
      }
    },

    async updateWorkingTime() {
      if (!this.workingTime || !this.duration) return;

      this.error = "";
      this.saving = true;

      try {
        await api.put(`/workingTime/${this.userId}/${this.workingTime.id}`, this.getPayload());
        showToast("Punch updated");
        this.$emit("saved");
      } catch (error) {
        console.error("UPDATE WORKING TIME ERROR:", error);
        this.error = errorMessage(error, "Could not update the punch.");
      } finally {
        this.saving = false;
      }
    },

    async deleteWorkingTime() {
      if (!this.workingTime) return;
      if (!window.confirm("Delete this punch? This can't be undone.")) return;

      this.error = "";
      this.saving = true;

      try {
        await api.delete(`/workingTime/${this.userId}/${this.workingTime.id}`);
        showToast("Punch deleted");
        this.$emit("deleted");
      } catch (error) {
        console.error("DELETE WORKING TIME ERROR:", error);
        this.error = errorMessage(error, "Could not delete the punch.");
      } finally {
        this.saving = false;
      }
    },

    cancelEdit() {
      this.error = "";
      this.$emit("cancel-edit");
    },
  },
};
</script>

<style scoped>
.punch-form {
  display: flex;
  flex-direction: column;
  gap: var(--tm-gap);
}

.times {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--tm-gap);
}

.tm-input {
  width: 100%;
}

.note {
  margin: -4px 0 0;
  color: var(--tm-accent-text);
  font-size: 14px;
  font-weight: 600;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: auto;
}

/* Create mode: one big dark button, like the mock */
.punch-form:not(.editing) .submit {
  width: 100%;
}

.tm-btn {
  background: transparent;
  color: var(--tm-ink);
}

.tm-btn--dark {
  background: var(--tm-ink);
  color: var(--tm-ground);
}

.delete {
  border-color: var(--tm-danger);
  color: var(--tm-danger);
}

/* Inline edit: the three fields on one line when there is room */
.punch-form.editing {
  display: grid;
  grid-template-columns: minmax(150px, 1fr) minmax(220px, 2fr);
  align-items: end;
}

.punch-form.editing .note,
.punch-form.editing .error-msg,
.punch-form.editing .actions {
  grid-column: 1 / -1;
}

@media (max-width: 640px) {
  .punch-form.editing {
    grid-template-columns: 1fr;
  }
}
</style>
