'use client';

const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/v1';

const ACCESS_KEY = 'wapa_admin_access_token';

export function setAccessToken(token: string | null) {
  if (typeof window === 'undefined') return;
  if (token) localStorage.setItem(ACCESS_KEY, token);
  else localStorage.removeItem(ACCESS_KEY);
}

export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(ACCESS_KEY);
}

interface ApiError extends Error {
  status: number;
  type?: string;
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getAccessToken();
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init.headers ?? {}),
    },
  });
  if (!res.ok) {
    const body = await res.text();
    let parsed: Record<string, unknown> = {};
    try { parsed = JSON.parse(body); } catch { /* RFC 7807 body or empty */ }
    const err: ApiError = Object.assign(new Error(
      (parsed.detail as string) ?? (parsed.title as string) ?? `HTTP ${res.status}`
    ), { status: res.status, type: parsed.type as string });
    throw err;
  }
  return res.status === 204 ? (undefined as T) : (res.json() as Promise<T>);
}

export const api = {
  async login(email: string, password: string) {
    const res = await request<{ access_token: string; refresh_token: string; user: { id: string; email: string } }>(
      '/auth/login',
      { method: 'POST', body: JSON.stringify({ email, password }) },
    );
    setAccessToken(res.access_token);
    return res;
  },
  async loginWithGoogle(idToken: string) {
    const res = await request<{ access_token: string; refresh_token: string; user: { id: string; email: string } }>(
      '/auth/google',
      { method: 'POST', body: JSON.stringify({ id_token: idToken }) },
    );
    setAccessToken(res.access_token);
    return res;
  },
  logout() { setAccessToken(null); },
  listFlags(status?: 'open' | 'reviewing' | 'cleared' | 'escalated') {
    const q = status ? `?status=${status}` : '';
    return request<ComplianceFlag[]>(`/admin/compliance/flags${q}`);
  },
  reviewFlag(id: string, decision: 'cleared' | 'escalated', note: string) {
    return request<ComplianceFlag>(`/admin/compliance/flags/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ decision, note }),
    });
  },
};

export interface ComplianceFlag {
  id: string;
  user_id: string;
  transfer_id: string | null;
  rule_id: string;
  severity: 'low' | 'medium' | 'high' | 'block';
  status: 'open' | 'reviewing' | 'cleared' | 'escalated';
  reason: string;
  created_at: string;
  reviewer_note: string | null;
}
