<template>
  <div
    v-if="message"
    class="sync-banner"
    :class="kind"
    role="status"
  >
    <span>{{ message }}</span>

    <button
      v-if="error"
      class="dismiss"
      aria-label="Dismiss"
      @click="dismiss"
    >
      ×
    </button>
  </div>
</template>

<script>
import { online, syncing, pendingCount, lastSyncError } from "../offline";

export default {
  name: "SyncBanner",

  computed: {
    error() {
      return lastSyncError.value;
    },

    kind() {
      if (this.error) return "error";
      if (!online.value) return "offline";
      return "syncing";
    },

    message() {
      const n = pendingCount.value;
      const waiting = n ? `, ${n} action${n > 1 ? "s" : ""} waiting to sync` : "";

      if (this.error) return this.error;
      if (!online.value) return `You're offline${waiting}.`;
      if (syncing.value || n) return `Syncing${waiting}...`;
      return "";
    },
  },

  methods: {
    dismiss() {
      lastSyncError.value = "";
    },
  },
};
</script>

<style scoped>
.sync-banner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 600;
  text-align: center;
}

.offline {
  background: #fef3c7;
  color: #92400e;
}

.syncing {
  background: #e0e7ff;
  color: #3730a3;
}

.error {
  background: #fee2e2;
  color: #991b1b;
}

.dismiss {
  padding: 0 8px;
  background: transparent;
  color: inherit;
  border: none;
  font-size: 18px;
  line-height: 1;
}
</style>
