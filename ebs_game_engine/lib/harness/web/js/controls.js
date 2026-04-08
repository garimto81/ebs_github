/**
 * controls.js — Action buttons + amount slider
 */

let _callback = null;
let _currentState = null;
let _pendingActionType = null; // 'bet' or 'raise'

const actionRow   = () => document.getElementById('action-row');
const amountRow   = () => document.getElementById('amount-row');
const amountSlider = () => document.getElementById('amount-slider');
const amountInput  = () => document.getElementById('amount-input');
const sendBtn      = () => document.getElementById('btn-send');
const presetsDiv   = () => document.getElementById('amount-presets');

/**
 * Initialize controls.
 * @param {function} callback - called with action object {type, amount?}
 */
export function initControls(callback) {
  _callback = callback;

  // Sync slider ↔ number input
  amountSlider().addEventListener('input', () => {
    amountInput().value = amountSlider().value;
  });
  amountInput().addEventListener('input', () => {
    const v = parseInt(amountInput().value) || 0;
    amountSlider().value = v;
  });

  // Send button
  sendBtn().addEventListener('click', () => {
    if (!_pendingActionType || !_callback) return;
    const amount = parseInt(amountInput().value) || 0;
    _callback({ type: _pendingActionType, amount });
    hideAmountRow();
  });

  // Preset buttons
  presetsDiv().addEventListener('click', (e) => {
    const preset = e.target.dataset.preset;
    if (!preset || !_currentState) return;
    const amount = resolvePreset(preset, _currentState, _pendingActionType);
    if (amount !== null) {
      amountInput().value = amount;
      amountSlider().value = amount;
    }
  });
}

function resolvePreset(preset, state, actionType) {
  const pot = state.pot?.total ?? 0;
  const legalActions = state.legalActions || [];
  const la = legalActions.find(a => a.type === actionType);
  const min = la?.minAmount ?? la?.callAmount ?? 0;
  const max = la?.maxAmount ?? (state.seats?.find(s => s.index === state.actionOn)?.stack ?? 0);

  switch (preset) {
    case 'min':    return min;
    case 'half':   return Math.max(min, Math.round(pot / 2));
    case 'pot':    return Math.max(min, pot);
    case 'allin':  return max;
    default:       return null;
  }
}

function hideAmountRow() {
  amountRow().style.display = 'none';
  _pendingActionType = null;
}

function showAmountRow(type, state) {
  _pendingActionType = type;
  const legalActions = state.legalActions || [];
  const la = legalActions.find(a => a.type === type);
  const min = la?.minAmount ?? la?.callAmount ?? 0;
  const max = la?.maxAmount ?? (state.seats?.find(s => s.index === state.actionOn)?.stack ?? 0);

  amountSlider().min = min;
  amountSlider().max = max;
  amountSlider().value = min;
  amountInput().min = min;
  amountInput().max = max;
  amountInput().value = min;

  amountRow().style.display = 'flex';
}

/**
 * Update internal state reference (for preset calculations).
 * @param {Object} state
 */
export function setSession(state) {
  _currentState = state;
}

/**
 * Render action buttons from state.legalActions.
 * @param {Object} state
 */
export function renderActions(state) {
  _currentState = state;
  const row = actionRow();
  row.innerHTML = '';
  hideAmountRow();

  const actions = state?.legalActions || [];
  if (!actions.length) {
    row.innerHTML = '<span class="no-actions">Waiting…</span>';
    return;
  }

  actions.forEach(action => {
    const btn = document.createElement('button');
    btn.className = `btn action-btn ${action.type}`;

    switch (action.type) {
      case 'fold':
        btn.textContent = 'Fold';
        btn.addEventListener('click', () => _callback?.({ type: 'fold' }));
        break;

      case 'check':
        btn.textContent = 'Check';
        btn.addEventListener('click', () => _callback?.({ type: 'check' }));
        break;

      case 'call':
        btn.textContent = `Call $${action.callAmount ?? ''}`;
        btn.addEventListener('click', () => _callback?.({ type: 'call' }));
        break;

      case 'bet':
        btn.textContent = 'Bet';
        btn.addEventListener('click', () => showAmountRow('bet', state));
        break;

      case 'raise':
        btn.textContent = `Raise (min $${action.minAmount ?? ''})`;
        btn.addEventListener('click', () => showAmountRow('raise', state));
        break;

      case 'all_in':
        btn.textContent = `All-In ($${action.maxAmount ?? ''})`;
        btn.addEventListener('click', () => _callback?.({ type: 'all_in', amount: action.maxAmount }));
        break;

      default:
        btn.textContent = action.type;
        btn.addEventListener('click', () => _callback?.({ type: action.type }));
    }

    row.appendChild(btn);
  });
}
