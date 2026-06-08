import type { Config } from 'tailwindcss'

// Tailwind handles LAYOUT/typography utilities only; the cabinet skin (CRT/levers/textures) is
// bespoke CSS in src/cabinet.css — the same design language as ferriswheel_bridge (keep in sync).
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // phosphor terminal scale (CRT screens)
        phos: {
          dim: '#2f8a48',
          DEFAULT: '#7dff9e',
          bright: '#9dffb4',
          line: '#36d860',
        },
      },
    },
  },
  plugins: [],
} satisfies Config
