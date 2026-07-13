/** @type {import('next').NextConfig} */
const nextConfig = {
  // Static export — deployable to S3/CloudFront/Vercel-static/Netlify.
  output: 'export',
  images: { unoptimized: true },
  env: {
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL ?? 'https://api.wapaexchange.com/v1',
  },
};
export default nextConfig;
