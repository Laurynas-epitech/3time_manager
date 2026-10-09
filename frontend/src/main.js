import { createApp } from 'vue'
import './styles/tokens.css'
import App from './App.vue'
import router from './router'

import { registerSW } from 'virtual:pwa-register'
import { dbPromise } from './services/offlinedb'
import { startAttendanceSync, markOfflineReady } from './services/attendance'

createApp(App).use(router).mount('#app')
startAttendanceSync()


dbPromise
  .then((db) => {
    console.log('IndexedDB initialized:', db.name)
  })
  .catch((error) => {
    console.error('IndexedDB initialization failed:', error)
  })

registerSW({
  immediate: true,

  onOfflineReady() {
    markOfflineReady()
    console.log('App is ready for offline use')
  },

  onNeedRefresh() {
    console.log('New app version available')
  },

  onRegisterError(error) {
    console.error('Service worker error:', error)
  }
})

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.ready.then(() => {
    if (navigator.serviceWorker.controller) markOfflineReady()
  })
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (navigator.serviceWorker.controller) markOfflineReady()
  })
}
