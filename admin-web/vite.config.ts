import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/again26/admin/',
  build: {
    outDir: '../web/admin',
    emptyOutDir: true,
  },
  server: {
    port: 5173,
    proxy: {},
  },
});
