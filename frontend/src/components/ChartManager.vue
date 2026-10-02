<template>
  <div>
    <div
      v-if="workingTimes.length === 0"
      class="empty-charts"
    >
      <strong>No chart data available.</strong>

      <span>
        Add working times for this user to display statistics.
      </span>
    </div>

    <div v-else>
      <div class="chart-summary">
        <div class="stat">
          <span>Total hours</span>

          <strong>
            {{ totalHours.toFixed(1) }}
          </strong>
        </div>

        <div class="stat">
          <span>Entries</span>

          <strong>
            {{ workingTimes.length }}
          </strong>
        </div>

        <div class="stat">
          <span>Average</span>

          <strong>
            {{ averageHours.toFixed(1) }} h
          </strong>
        </div>
      </div>

      <div class="charts-grid">
        <div class="chart-box">
          <h3>Hours Worked</h3>

          <Bar
            :data="chartData"
            :options="chartOptions"
          />
        </div>

        <div class="chart-box">
          <h3>Working Time Trend</h3>

          <Line
            :data="chartData"
            :options="chartOptions"
          />
        </div>

        <div class="chart-box">
          <h3>Hours Distribution</h3>

          <Pie
            :data="chartData"
            :options="pieOptions"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";

import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  CategoryScale,
  LinearScale,
} from "chart.js";

import {
  Bar,
  Line,
  Pie,
} from "vue-chartjs";

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  CategoryScale,
  LinearScale
);

export default {
  name: "ChartManager",

  components: {
    Bar,
    Line,
    Pie,
  },

  props: {
    userId: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      workingTimes: [],
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

  computed: {
    hours() {
      return this.workingTimes.map(
        (workingTime) => {
          const start =
            new Date(
              workingTime.start
            );

          const end =
            new Date(
              workingTime.end
            );

          return (
            (end - start) /
            (1000 * 60 * 60)
          );
        }
      );
    },

    totalHours() {
      return this.hours.reduce(
        (total, hours) =>
          total + hours,
        0
      );
    },

    averageHours() {
      if (this.hours.length === 0) {
        return 0;
      }

      return (
        this.totalHours /
        this.hours.length
      );
    },

    chartData() {
      return {
        labels:
          this.workingTimes.map(
            (workingTime) =>
              new Date(
                workingTime.start
              ).toLocaleDateString(
                undefined,
                {
                  day: "2-digit",
                  month: "short",
                }
              )
          ),

        datasets: [
          {
            label: "Hours Worked",
            data: this.hours,

            backgroundColor:
              "rgba(79, 70, 229, 0.55)",

            borderColor:
              "rgb(79, 70, 229)",

            borderWidth: 2,

            tension: 0.3,
          },
        ],
      };
    },

    chartOptions() {
      return {
        responsive: true,
        maintainAspectRatio: false,

        plugins: {
          legend: {
            display: false,
          },
        },

        scales: {
          y: {
            beginAtZero: true,
          },
        },
      };
    },

    pieOptions() {
      return {
        responsive: true,
        maintainAspectRatio: false,
      };
    },
  },

  methods: {
  async getWorkingTimes() {
    if (!this.userId) {
      this.workingTimes = [];
      return;
    }

    try {
      const response = await axios.get(
        `http://57.130.61.152:4000/api/chartManager/${this.userId}`
      );

      const data =
        response.data.data ?? response.data;

      this.workingTimes =
        Array.isArray(data)
          ? data
          : [];
    } catch (error) {
      console.error(
        "CHART ERROR:",
        error
      );

      this.workingTimes = [];
    }
  },
},
};
</script>

<style scoped>
.chart-summary {
  display: grid;
  grid-template-columns:
    repeat(3, 1fr);

  gap: 15px;

  margin-bottom: 25px;
}

.stat {
  padding: 18px;

  background: #f8fafc;

  border: 1px solid #e5e7eb;
  border-radius: 12px;

  display: flex;
  flex-direction: column;
  gap: 5px;
}

.stat span {
  color: #6b7280;
  font-size: 12px;
}

.stat strong {
  color: #111827;
  font-size: 24px;
}

.charts-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;

  gap: 20px;
}

.chart-box {
  height: 340px;

  padding: 18px;

  background: #fafafa;

  border: 1px solid #e5e7eb;
  border-radius: 12px;
}

.chart-box:last-child {
  grid-column: span 2;

  max-width: 600px;
  width: 100%;

  justify-self: center;
}

.chart-box h3 {
  margin: 0 0 15px;

  color: #374151;
  font-size: 14px;
}

.empty-charts {
  padding: 50px 20px;

  text-align: center;

  border: 1px dashed #d1d5db;
  border-radius: 12px;

  display: flex;
  flex-direction: column;
  gap: 6px;

  color: #6b7280;
}

@media (max-width: 750px) {
  .chart-summary {
    grid-template-columns: 1fr;
  }

  .charts-grid {
    grid-template-columns: 1fr;
  }

  .chart-box:last-child {
    grid-column: span 1;
  }
}
</style>