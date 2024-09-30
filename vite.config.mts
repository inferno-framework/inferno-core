/// <reference types="vitest" />

import { defineConfig } from 'vite';
import path from 'path';
import eslint from 'vite-plugin-eslint2';

export default defineConfig({
  clearScreen: true,
  test: {
    root: './client',
    setupFiles: ['./client/src/setupTests.ts'],
    environment: 'jsdom',
    globals: true,
    coverage: {
      reportsDirectory: path.resolve(__dirname, './client/coverage'),
    },
  },
  resolve: {
    alias: {
      '~': path.resolve(__dirname, './client/src'),
      components: path.resolve(__dirname, './client/src/components'),
      styles: path.resolve(__dirname, './client/src/styles'),
      models: path.resolve(__dirname, './client/src/models'),
      api: path.resolve(__dirname, './client/src/api'),
    },
  },
  plugins: [eslint()],
});
