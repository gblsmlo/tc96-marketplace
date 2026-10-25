import type { Config } from 'tailwindcss'
import animate from 'tailwindcss-animate'

export default {
  content: ['./src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: '#0f766e',
      },
    },
  },
  safelist: ['bg-red-500'],
  plugins: [animate],
} satisfies Config
