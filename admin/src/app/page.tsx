'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getAccessToken } from '@/lib/api';

export default function Index() {
  const router = useRouter();
  useEffect(() => {
    router.replace(getAccessToken() ? '/flags' : '/login');
  }, [router]);
  return null;
}
