import { ref } from "vue";
import { isNative } from "./native";

// Mobile layout: inside the Android app, or on a narrow browser window.
const query = window.matchMedia("(max-width: 768px)");

export const isMobile = ref(isNative || query.matches);

query.addEventListener("change", (event) => {
  isMobile.value = isNative || event.matches;
});
