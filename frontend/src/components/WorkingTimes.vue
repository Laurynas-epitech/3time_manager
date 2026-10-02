<template>
  <div>
    <div
      v-if="loading"
      class="empty-state"
    >
      Loading working times...
    </div>

    <div
      v-else-if="workingTimes.length === 0"
      class="empty-state"
    >
      <strong>No working times yet.</strong>

      <span>
        Add a working-time entry above to get started.
      </span>
    </div>

    <div
      v-else
      class="working-list"
    >
      <div
        v-for="workingTime in workingTimes"
        :key="workingTime.id"
        class="working-row"
      >
        <div class="working-date">
          <strong>
            {{ formatDate(workingTime.start) }}
          </strong>

          <span>
            {{ formatTime(workingTime.start) }}
            →
            {{ formatTime(workingTime.end) }}
          </span>
        </div>

        <div class="working-hours">
          {{ calculateHours(workingTime) }}
        </div>

        <button
          class="secondary"
          @click="$emit(
            'edit-working-time',
            workingTime
          )"
        >
          Edit
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "WorkingTimes",

  props: {
  userId: {
    type: Number,
    required: true,
  },
},

data() {
  return {
    workingTimes: [],
    loading: false,
  };
},

watch: {
  userId: {
    immediate: true,

    handler() {
      this.getWorkingTimes();
    },
  },
},

  methods: {
    async getWorkingTimes() {
      if (!this.userId) {
        this.workingTimes = [];
        return;
      }

      this.loading = true;

      try {
        const response = await axios.get(
  `http://57.130.61.152:4000/api/workingtime/${this.userId}`
);

        const data =
          response.data.data ?? response.data;

        this.workingTimes =
          Array.isArray(data) ? data : [];
      } catch (error) {
        console.error(
          "GET WORKING TIMES ERROR:",
          error
        );

        this.workingTimes = [];
      } finally {
        this.loading = false;
      }
    },

    formatDate(value) {
      return new Date(value).toLocaleDateString(
        undefined,
        {
          day: "2-digit",
          month: "short",
          year: "numeric",
        }
      );
    },

    formatTime(value) {
      return new Date(value).toLocaleTimeString(
        undefined,
        {
          hour: "2-digit",
          minute: "2-digit",
        }
      );
    },

    calculateHours(workingTime) {
      const start =
        new Date(workingTime.start);

      const end =
        new Date(workingTime.end);

      const hours =
        (end - start) /
        (1000 * 60 * 60);

      return `${hours.toFixed(1)} h`;
    },
  },
};
</script>

<style scoped>
.working-list {
  display: grid;
  gap: 10px;
}

.working-row {
  display: grid;

  grid-template-columns:
    minmax(200px, 1fr)
    100px
    auto;

  align-items: center;

  gap: 15px;

  padding: 14px 16px;

  background: #f8fafc;

  border: 1px solid #e5e7eb;
  border-radius: 10px;
}

.working-date {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.working-date strong {
  color: #1f2937;
}

.working-date span {
  color: #6b7280;
  font-size: 13px;
}

.working-hours {
  color: #4f46e5;
  font-weight: 700;
}

.empty-state {
  padding: 35px;

  text-align: center;

  border: 1px dashed #d1d5db;
  border-radius: 10px;

  color: #6b7280;

  display: flex;
  flex-direction: column;
  gap: 5px;
}

@media (max-width: 650px) {
  .working-row {
    grid-template-columns: 1fr;
  }
}
</style>