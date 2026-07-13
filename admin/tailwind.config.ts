import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: { DEFAULT: '#1a6cf2', dark: '#0f47b2' },
        danger: '#d6363e',
        warning: '#f59e0b',
        success: '#28a85f',
      },
    },
  },
  plugins: [],
};
export default config;
