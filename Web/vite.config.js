/* eslint-disable import/no-extraneous-dependencies -- demo devDependencies */
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import basicSsl from '@vitejs/plugin-basic-ssl';
import { defineConfig } from 'vite';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig(({ command, isPreview }) => ({
  plugins: [
    command === 'serve' && !isPreview ? basicSsl() : null
  ].filter(Boolean),
  root: __dirname,
  resolve: { dedupe: ['agora-rtc-sdk-ng'] },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: false
  },
  server: {
    port: 5175,
    host: true,
    https: true,
    open: true
  },
  preview: {
    host: true,
    port: 5175
  }
}));
