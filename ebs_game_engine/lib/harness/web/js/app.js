/**
 * app.js — Main entry point for EBS Game Engine Interactive Simulator
 */

import { createSession, getSession, sendEvent, undo, saveSession, listScenarios, listVariants } from './api.js';
import { renderTable } from './table-view.js';
import { initControls, renderActions, setSession } from './controls.js';
import { renderLog } from './event-log.js';
import { initTimeline, updateTimeline } from './timeline.js';
import { initManualDeal, setDealState } from './manual-deal.js';

// ─── State ───────────────────────────────────────────────────────────────────
let _sessionId = null;
let _currentState = null;

// ─── DOM refs ─────────────────────────────────────────────────────────────────
const svg         = () => document.getElementById('table-svg');
const lblVariant  = () => document.getElementById('lbl-variant');
const lblStreet   = () => document.getElementById('lbl-street');
const selVariant  = () => document.getElementById('sel-variant');
const selSeats    = () => document.getElementById('sel-seats');
const inpStack    = () => document.getElementById('inp-stack');
const inpBB       = () => document.getElementById('inp-bb');
const btnNewHand  = () => document.getElementById('btn-new-hand');
const btnUndo     = () => document.getElementById('btn-undo');
const btnSave     = () => document.getElementById('btn-save');
const selScenario = () => document.getElementById('sel-scenario');

// ─── Update ───────────────────────────────────────────────────────────────────
function update(state) {
  _currentState = state;

  renderTable(svg(), state);
  renderActions(state);
  renderLog(state, seek);
  updateTimeline(state);
  setSession(state);
  setDealState(state);

  // Header labels
  if (lblVariant()) lblVariant().textContent = state.variant || 'NL Hold\'em';
  if (lblStreet())  lblStreet().textContent  = state.street  || '';
}

// ─── Seek (replay / timeline) ─────────────────────────────────────────────────
async function seek(cursor) {
  if (!_sessionId) return;
  try {
    const state = await getSession(_sessionId, cursor);
    update(state);
  } catch (err) {
    showError('Seek failed: ' + err.message);
  }
}

// ─── Action handler ───────────────────────────────────────────────────────────
async function onAction(action) {
  if (!_sessionId || !_currentState) return;

  // In replay mode — jump to live before acting
  const isReplay = (_currentState.cursor ?? 0) < (_currentState.eventCount ?? 0);
  if (isReplay) {
    try {
      const live = await getSession(_sessionId);
      update(live);
    } catch (err) {
      showError('Failed to exit replay: ' + err.message);
      return;
    }
  }

  try {
    const actionSeat = _currentState.actionOn;
    const payload = { ...action, seatIndex: actionSeat };
    const state = await sendEvent(_sessionId, payload);
    update(state);
  } catch (err) {
    showError('Action failed: ' + err.message);
  }
}

// ─── New Hand ─────────────────────────────────────────────────────────────────
async function newHand() {
  const variant   = selVariant().value;
  const seatCount = parseInt(selSeats().value) || 6;
  const stack     = parseInt(inpStack().value) || 1000;
  const bb        = parseInt(inpBB().value)    || 20;
  const sb        = Math.max(1, Math.floor(bb / 2));

  const stacks = Array(seatCount).fill(stack);

  try {
    btnNewHand().disabled = true;
    const data = await createSession({
      variant,
      seatCount,
      stacks,
      blinds: { sb, bb },
      dealerSeat: 0,
    });
    _sessionId = data.sessionId;
    const state = await getSession(_sessionId);
    update(state);
  } catch (err) {
    showError('New hand failed: ' + err.message);
  } finally {
    btnNewHand().disabled = false;
  }
}

// ─── Undo ─────────────────────────────────────────────────────────────────────
async function onUndo() {
  if (!_sessionId) return;
  try {
    const state = await undo(_sessionId);
    update(state);
  } catch (err) {
    showError('Undo failed: ' + err.message);
  }
}

// ─── Save ─────────────────────────────────────────────────────────────────────
async function onSave() {
  if (!_sessionId) return;
  try {
    const result = await saveSession(_sessionId);
    const msg = typeof result === 'string' ? result : JSON.stringify(result);
    showToast('Saved: ' + msg);
  } catch (err) {
    showError('Save failed: ' + err.message);
  }
}

// ─── Load Scenario ────────────────────────────────────────────────────────────
async function onLoadScenario() {
  const file = selScenario().value;
  if (!file) return;

  try {
    // Create a session from scenario — POST /api/session with scenario field
    const data = await createSession({ scenario: file });
    _sessionId = data.sessionId;
    const state = await getSession(_sessionId);
    update(state);
    selScenario().value = '';
  } catch (err) {
    showError('Load scenario failed: ' + err.message);
  }
}

// ─── Init variants dropdown ───────────────────────────────────────────────────
async function initVariants() {
  try {
    const data = await listVariants();
    const variants = data.variants || [];
    if (!variants.length) return;

    const sel = selVariant();
    sel.innerHTML = '';
    variants.forEach(v => {
      const opt = document.createElement('option');
      opt.value = v;
      opt.textContent = v;
      sel.appendChild(opt);
    });
  } catch {
    // Server may not be running yet — silently ignore
  }
}

// ─── Init scenarios dropdown ──────────────────────────────────────────────────
async function initScenarios() {
  try {
    const data = await listScenarios();
    const scenarios = data.scenarios || [];
    const sel = selScenario();

    scenarios.forEach(file => {
      const opt = document.createElement('option');
      opt.value = file;
      opt.textContent = file.replace(/\.yaml$/, '');
      sel.appendChild(opt);
    });
  } catch {
    // Ignore
  }
}

// ─── Manual deal apply ────────────────────────────────────────────────────────
document.addEventListener('manual-deal-apply', async (e) => {
  if (!_sessionId) return;
  const { assignments } = e.detail;
  // Convert assignments to an event payload
  // Build hole card overrides per seat and community overrides
  const seatCards = {};
  const community = [];

  for (const [key, card] of Object.entries(assignments)) {
    if (!card) continue;
    const seatMatch = key.match(/^seat-(\d+)-(\d+)$/);
    if (seatMatch) {
      const seatIdx = parseInt(seatMatch[1]);
      const cardIdx = parseInt(seatMatch[2]);
      if (!seatCards[seatIdx]) seatCards[seatIdx] = [];
      seatCards[seatIdx][cardIdx] = card;
    }
    const commMatch = key.match(/^community-(\d+)$/);
    if (commMatch) {
      community[parseInt(commMatch[1])] = card;
    }
  }

  try {
    // Send as a special ManualDeal event
    const payload = {
      type: 'manual_deal',
      seatCards,
      community: community.filter(Boolean),
    };
    const state = await sendEvent(_sessionId, payload);
    update(state);
  } catch (err) {
    showError('Manual deal failed: ' + err.message);
  }
});

// ─── Toast / Error ────────────────────────────────────────────────────────────
function showError(msg) {
  console.error(msg);
  showToast(msg, true);
}

function showToast(msg, isError = false) {
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.textContent = msg;
  Object.assign(toast.style, {
    position: 'fixed',
    bottom: '20px',
    right: '20px',
    background: isError ? '#cc2200' : '#1e5c3a',
    color: '#fff',
    padding: '10px 18px',
    borderRadius: '6px',
    border: `1px solid ${isError ? '#ff4422' : '#246b44'}`,
    boxShadow: '0 4px 16px rgba(0,0,0,.5)',
    zIndex: '9999',
    maxWidth: '400px',
    fontSize: '13px',
    fontFamily: 'Consolas, monospace',
    transition: 'opacity .3s',
  });

  document.body.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ─── Wire buttons ─────────────────────────────────────────────────────────────
btnNewHand().addEventListener('click', newHand);
btnUndo().addEventListener('click', onUndo);
btnSave().addEventListener('click', onSave);
selScenario().addEventListener('change', onLoadScenario);

// ─── Init modules ─────────────────────────────────────────────────────────────
initControls(onAction);
initTimeline(seek);
initManualDeal();
initVariants();
initScenarios();
