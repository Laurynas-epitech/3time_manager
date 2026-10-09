<template>
  <!-- Always in the DOM so screen readers announce new messages -->
  <div
    class="toast-region"
    role="status"
    aria-live="polite"
  >
    <transition name="toast">
      <div
        v-if="toastState.message"
        :key="toastState.id"
        class="toast"
      >
        {{ toastState.message }}
      </div>
    </transition>
  </div>
</template>

<script>
import { toastState } from "../toast";

export default {
  name: "AppToast",

  data() {
    return { toastState };
  },
};
</script>

<style scoped>
.toast-region {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 24px;
  z-index: 50;
  display: flex;
  justify-content: center;
  pointer-events: none;
}

.toast {
  padding: 12px 22px;
  border-radius: var(--tm-radius-pill);
  background: var(--tm-ink);
  color: var(--tm-ground);
  font-weight: 700;
  box-shadow: var(--tm-shadow-sm);
}

.toast-enter-active,
.toast-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Above the mobile tab bar */
@media (max-width: 640px) {
  .toast-region {
    bottom: 96px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .toast-enter-active,
  .toast-leave-active {
    transition: none;
  }
}
</style>
