<template>
  <div
    class="range-chips"
    role="group"
    :aria-label="label"
  >
    <button
      v-for="option in options"
      :key="option.id"
      type="button"
      class="tm-chip"
      :aria-pressed="String(option.id === modelValue)"
      @click="$emit('update:modelValue', option.id)"
    >
      {{ option.label }}
    </button>
  </div>
</template>

<script>
export default {
  name: "RangeChips",

  props: {
    // [{ id, label }]
    options: {
      type: Array,
      required: true,
    },

    modelValue: {
      type: String,
      required: true,
    },

    label: {
      type: String,
      default: "Range",
    },
  },

  emits: ["update:modelValue"],
};
</script>

<style scoped>
.range-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

/* tokens.css styles .tm-chip; reset the global dark button look */
.tm-chip {
  background: transparent;
  color: var(--tm-ink);
  min-height: var(--tm-hit);
  padding: 0 16px;
}

.tm-chip[aria-pressed="true"] {
  background: var(--tm-ink);
  color: var(--tm-ground);
}
</style>
