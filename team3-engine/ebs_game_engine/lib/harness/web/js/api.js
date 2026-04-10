/**
 * api.js — EBS Game Engine HTTP client
 * All functions return parsed JSON or throw on HTTP error.
 */

const BASE = '';

async function request(method, path, body) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  };
  if (body !== undefined) opts.body = JSON.stringify(body);

  const res = await fetch(BASE + path, opts);
  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`${method} ${path} → ${res.status}: ${text}`);
  }
  const ct = res.headers.get('content-type') || '';
  if (ct.includes('application/json')) return res.json();
  return res.text();
}

/**
 * Create a new session.
 * @param {Object} opts - {variant, seatCount, stacks, blinds:{sb,bb}, dealerSeat, seed}
 */
export async function createSession(opts) {
  return request('POST', '/api/session', opts);
}

/**
 * Get session state.
 * @param {string} id - session id
 * @param {number} [cursor] - event cursor
 */
export async function getSession(id, cursor) {
  const qs = cursor !== undefined ? `?cursor=${cursor}` : '';
  return request('GET', `/api/session/${id}${qs}`);
}

/**
 * Send a player action.
 * @param {string} id - session id
 * @param {Object} event - {type, seatIndex, amount?}
 */
export async function sendEvent(id, event) {
  return request('POST', `/api/session/${id}/event`, event);
}

/**
 * Undo the last action.
 * @param {string} id - session id
 */
export async function undo(id) {
  return request('POST', `/api/session/${id}/undo`);
}

/**
 * Save the session as YAML.
 * @param {string} id - session id
 */
export async function saveSession(id) {
  return request('POST', `/api/session/${id}/save`);
}

/**
 * List available scenarios.
 * @returns {Promise<{scenarios: string[]}>}
 */
export async function listScenarios() {
  return request('GET', '/api/scenarios');
}

/**
 * List available game variants.
 * @returns {Promise<{variants: string[]}>}
 */
export async function listVariants() {
  return request('GET', '/api/variants');
}
