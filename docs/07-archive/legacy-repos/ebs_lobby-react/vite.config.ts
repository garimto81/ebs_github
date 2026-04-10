import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    watch: {
      usePolling: true,  // Docker volume mount에서 파일 변경 감지 보장
    },
    proxy: {
      '/api': {
        target: process.env.API_BASE_URL || 'http://bo:8000',
        changeOrigin: true,
      },
      '/ws': {
        target: `ws://${process.env.API_BASE_URL?.replace('http://', '') || 'bo:8000'}`,
        ws: true,
      },
    },
  },
})
