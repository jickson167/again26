import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/again26/',
  build: {
    outDir: '../build/web',
    emptyOutDir: true,
  },
  server: {
    port: 5173,
  },
});
