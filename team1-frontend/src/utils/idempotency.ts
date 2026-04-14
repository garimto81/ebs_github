// src/utils/idempotency.ts — Idempotency-Key generator (CCR-019).
// Axios boot interceptor auto-injects a UUIDv4 for POST/PUT/PATCH/DELETE.
// Callers that implement retry logic must reuse the same key on retry so
// the server can deduplicate.

export function generateIdempotencyKey(): string {
  // crypto.randomUUID is available in all modern browsers + Node 19+.
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  // Fallback (should not hit in practice).
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
