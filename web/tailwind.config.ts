import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: { DEFAULT: '#1a6cf2', dark: '#0f47b2' },
        accent: '#f5a623',
        success: '#28a85f',
      },
      fontFamily: {
        sans: ['ui-rounded', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
export default config;
