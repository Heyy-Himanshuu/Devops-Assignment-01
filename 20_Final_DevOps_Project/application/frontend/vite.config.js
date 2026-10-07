import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// `npm run dev` proxies /api to a backend on :8000 (e.g. `docker compose up backend`).
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: { '/api': 'http://localhost:8000' } },
});
