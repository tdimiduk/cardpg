import path from 'path';
import { loadEnv } from 'vite';
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, '.', '');
    return {
      server: {
        port: 3000,
        host: '0.0.0.0',
        fs: {
          allow: ['..']
        },
        proxy: {
          '/api': {
            target: 'ws://127.0.0.1:8080',
            ws: true,
            changeOrigin: true,
            rewrite: (path) => path.replace(/^\/api/, ''),
          },
        },
      },
      plugins: [react()],
      define: {
        'process.env.API_KEY': JSON.stringify(env.GEMINI_API_KEY),
        'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY)
      },
      resolve: {
        alias: {
          '@': path.resolve(__dirname, './src'),
        }
      },
      build: {
        rollupOptions: {
          output: {
            manualChunks: {
              vendor: ['react', 'react-dom', 'lucide-react', 'zod', 'zustand', 'immer'],
            },
          },
        },
      },
      test: {
        environment: 'jsdom',
        globals: true,
        setupFiles: './src/tests/setup.ts'
      }
    };
});
