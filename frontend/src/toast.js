import { reactive, readonly } from "vue";

// One short message at a time, shown by <AppToast> at the bottom of the page.
const state = reactive({ message: "", id: 0 });
let timer = null;

export function showToast(message, duration = 3000) {
  state.message = message;
  state.id += 1;

  clearTimeout(timer);
  timer = setTimeout(() => {
    state.message = "";
  }, duration);
}

export const toastState = readonly(state);
