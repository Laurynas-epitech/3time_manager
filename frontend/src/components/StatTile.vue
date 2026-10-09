<template>
  <div
    class="tm-stat"
    :class="`stat--${tone}`"
  >
    <div class="tm-stat__label">{{ label }}</div>
    <div class="tm-stat__value">{{ value }}</div>
  </div>
</template>

<script>
export default {
  name: "StatTile",

  props: {
    label: {
      type: String,
      required: true,
    },

    value: {
      type: String,
      required: true,
    },

    // accent (tangerine) | primary (cobalt) | neutral
    tone: {
      type: String,
      default: "neutral",
    },
  },
};
</script>

<style scoped>
.stat--accent {
  background: var(--tm-accent-soft);
}

.stat--accent .tm-stat__label {
  color: var(--tm-accent-text);
}

.stat--primary {
  background: var(--tm-primary-soft);
}

.stat--primary .tm-stat__label {
  color: var(--tm-primary-text);
}

.stat--neutral {
  background: var(--tm-sunken);
}

.stat--neutral .tm-stat__label {
  color: var(--tm-ink-muted);
}
</style>
