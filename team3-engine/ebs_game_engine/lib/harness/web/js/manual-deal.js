/**
 * manual-deal.js — Manual card assignment modal.
 */

const RANKS = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
const SUITS = ['s', 'h', 'd', 'c'];
const SUIT_CHARS = { s: '♠', h: '♥', d: '♦', c: '♣' };
const RED_SUITS = new Set(['h', 'd']);

let _state = null;
let _assignments = {}; // slotKey → cardCode
let _selectedSlot = null; // { key, el }

export function initManualDeal() {
  const openBtn   = document.getElementById('btn-manual-deal');
  const modal     = document.getElementById('modal-manual-deal');
  const closeBtn  = document.getElementById('modal-close-btn');
  const cancelBtn = document.getElementById('modal-cancel');
  const applyBtn  = document.getElementById('modal-apply');

  openBtn.addEventListener('click', () => openModal());
  closeBtn.addEventListener('click', closeModal);
  cancelBtn.addEventListener('click', closeModal);
  applyBtn.addEventListener('click', applyAssignments);

  // Close on backdrop click
  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeModal();
  });
}

/**
 * Update the current session state (for building slot list + used cards).
 * @param {Object} state
 */
export function setDealState(state) {
  _state = state;
}

function openModal() {
  _assignments = {};
  _selectedSlot = null;
  buildSlots();
  buildCardGrid();
  document.getElementById('modal-manual-deal').style.display = 'flex';
}

function closeModal() {
  document.getElementById('modal-manual-deal').style.display = 'none';
  _selectedSlot = null;
}

function buildSlots() {
  const container = document.getElementById('deal-slots');
  container.innerHTML = '';

  if (!_state) {
    container.innerHTML = '<p style="color:#888">No active session.</p>';
    return;
  }

  const seats = _state.seats || [];

  // Seat hole cards
  seats.forEach(seat => {
    const group = document.createElement('div');
    group.className = 'deal-slot-group';

    const lbl = document.createElement('div');
    lbl.className = 'deal-slot-label';
    lbl.textContent = seat.label || `Seat ${seat.index}`;
    group.appendChild(lbl);

    const row = document.createElement('div');
    row.className = 'deal-slot-row';

    const numCards = 2; // hold'em default; could vary by variant
    for (let i = 0; i < numCards; i++) {
      const key = `seat-${seat.index}-${i}`;
      const existing = (seat.holeCards || [])[i];
      const slot = buildSlot(key, existing);
      row.appendChild(slot);
    }
    group.appendChild(row);
    container.appendChild(group);
  });

  // Community cards
  const commGroup = document.createElement('div');
  commGroup.className = 'deal-slot-group';
  const commLbl = document.createElement('div');
  commLbl.className = 'deal-slot-label';
  commLbl.textContent = 'Community';
  commGroup.appendChild(commLbl);

  const commRow = document.createElement('div');
  commRow.className = 'deal-slot-row';
  for (let i = 0; i < 5; i++) {
    const key = `community-${i}`;
    const existing = (_state.community || [])[i];
    commRow.appendChild(buildSlot(key, existing));
  }
  commGroup.appendChild(commRow);
  container.appendChild(commGroup);
}

function buildSlot(key, existingCard) {
  const slot = document.createElement('div');
  slot.className = 'deal-slot';
  slot.dataset.slotKey = key;

  if (existingCard) {
    _assignments[key] = existingCard;
    slot.classList.add('filled');
    renderSlotCard(slot, existingCard);
  } else {
    slot.textContent = '+';
  }

  slot.addEventListener('click', () => selectSlot(key, slot));
  return slot;
}

function renderSlotCard(slotEl, code) {
  slotEl.innerHTML = '';
  const rank = document.createElement('span');
  rank.className = 'slot-rank';
  rank.textContent = code.slice(0, -1);

  const suit = document.createElement('span');
  const s = code.slice(-1).toLowerCase();
  suit.className = `slot-suit ${RED_SUITS.has(s) ? 'red' : ''}`;
  suit.textContent = SUIT_CHARS[s] || s;

  slotEl.appendChild(rank);
  slotEl.appendChild(suit);
}

function selectSlot(key, el) {
  // Deselect previous
  if (_selectedSlot) {
    _selectedSlot.el.classList.remove('selected');
  }
  if (_selectedSlot?.key === key) {
    _selectedSlot = null;
    updateHint('Click a slot to select it, then click a card.');
    return;
  }
  _selectedSlot = { key, el };
  el.classList.add('selected');
  updateHint(`Slot selected — now click a card from the grid below.`);
}

function buildCardGrid() {
  const grid = document.getElementById('card-grid');
  grid.innerHTML = '';

  const usedCards = getUsedCards();

  SUITS.forEach(suit => {
    RANKS.forEach(rank => {
      const code = rank + suit;
      const card = document.createElement('div');
      card.className = `card-pick${RED_SUITS.has(suit) ? ' red' : ''}`;
      card.dataset.card = code;
      card.title = code;

      const r = document.createElement('div');
      r.textContent = rank;
      const s = document.createElement('div');
      s.textContent = SUIT_CHARS[suit];
      card.appendChild(r);
      card.appendChild(s);

      if (usedCards.has(code)) {
        card.classList.add('used');
      }

      card.addEventListener('click', () => assignCard(code, card));
      grid.appendChild(card);
    });
  });
}

function getUsedCards() {
  const used = new Set();
  // Cards in state (not in _assignments)
  if (_state) {
    (_state.community || []).forEach(c => { if (c) used.add(c); });
    (_state.seats || []).forEach(seat => {
      (seat.holeCards || []).forEach(c => { if (c) used.add(c); });
    });
  }
  // Cards in current assignments
  Object.values(_assignments).forEach(c => { if (c) used.add(c); });
  return used;
}

function assignCard(code, cardEl) {
  if (!_selectedSlot) {
    updateHint('Select a slot first, then click a card.');
    return;
  }

  const key = _selectedSlot.key;
  const slotEl = _selectedSlot.el;

  // Free the old assignment of this slot
  const old = _assignments[key];
  if (old) {
    const oldCardEl = document.querySelector(`.card-pick[data-card="${old}"]`);
    if (oldCardEl) oldCardEl.classList.remove('assigned', 'used');
  }

  _assignments[key] = code;
  cardEl.classList.add('assigned', 'used');

  // Update slot display
  slotEl.classList.remove('selected');
  slotEl.classList.add('filled');
  renderSlotCard(slotEl, code);

  _selectedSlot = null;
  updateHint('Card assigned. Select another slot or click Apply.');
}

function updateHint(text) {
  const hint = document.getElementById('modal-hint');
  if (hint) hint.textContent = text;
}

function applyAssignments() {
  // Dispatch a custom event that app.js can listen to
  const evt = new CustomEvent('manual-deal-apply', { detail: { assignments: { ..._assignments } } });
  document.dispatchEvent(evt);
  closeModal();
}
