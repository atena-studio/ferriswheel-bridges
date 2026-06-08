import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Build output goes to ../nui (committed, served statically by FiveM as the bridge's ui_page).
// base './' => relative asset paths so the nui:// scheme resolves them inside the resource.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: '../nui',
    emptyOutDir: true,
    assetsDir: 'assets',
  },
})
