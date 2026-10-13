import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  server: { proxy: { '/api': 'http://127.0.0.1:4000' } },
  preview: { proxy: { '/api': 'http://127.0.0.1:4000' } },
  plugins: [
    vue(),

    VitePWA({
      registerType: 'autoUpdate',

      manifest: {
        name: 'Time Manager',
        short_name: 'TimeManager',
        description: 'Employee attendance management',
        display: 'standalone',
        start_url: '/',
        scope: '/',
        theme_color: '#ffffff',
        background_color: '#ffffff'
      },

      workbox: {
        navigateFallback: '/index.html',
        navigateFallbackDenylist: [/^\/api(?:\/|$)/],
        globPatterns: [
          '**/*.{js,css,html,ico,png,svg,woff2}'
        ]
      }
    })
  ]
})
