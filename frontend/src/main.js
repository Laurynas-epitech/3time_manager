import { createApp } from "vue";
import "./style.css";
import App from "./App.vue";
import router from "./router";
import { initOffline } from "./offline";
import { initNative } from "./native";

async function start() {
  await initOffline();

  createApp(App).use(router).mount("#app");

  initNative();
}

start();
