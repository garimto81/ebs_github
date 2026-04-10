/**
 * table-view.js — SVG poker table renderer
 */

const SVG_NS = 'http://www.w3.org/2000/svg';

const CARD_W = 32;
const CARD_H = 46;

// Suit display helpers
const SUIT_CHARS = { s: '♠', h: '♥', d: '♦', c: '♣' };
const SUIT_CLASS = { s: 'suit-black', h: 'suit-red', d: 'suit-red', c: 'suit-black' };

function svgEl(tag, attrs = {}, text) {
  const el = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v);
  if (text !== undefined) el.textContent = text;
  return el;
}

function parseCard(code) {
  if (!code || code.length < 2) return null;
  const rank = code.slice(0, -1);
  const suit = code.slice(-1).toLowerCase();
  return { rank, suit };
}

/**
 * Draw a single card at (x, y) — top-left corner.
 * If code is null/undefined, draws a card back.
 */
function drawCard(parent, x, y, code) {
  const g = svgEl('g', { transform: `translate(${x},${y})` });

  if (!code) {
    // Card back — blue pattern
    const bg = svgEl('rect', { x: 0, y: 0, width: CARD_W, height: CARD_H, rx: 3, class: 'card-back' });
    g.appendChild(bg);
    // Simple hatching pattern
    const inner = svgEl('rect', { x: 2, y: 2, width: CARD_W - 4, height: CARD_H - 4, rx: 2,
      fill: 'none', stroke: 'rgba(255,255,255,.25)', 'stroke-width': 1 });
    g.appendChild(inner);
  } else {
    const card = parseCard(code);
    if (!card) return g;

    const bg = svgEl('rect', { x: 0, y: 0, width: CARD_W, height: CARD_H, rx: 3, class: 'card-bg' });
    g.appendChild(bg);

    const cls = SUIT_CLASS[card.suit] || 'suit-black';
    const suitChar = SUIT_CHARS[card.suit] || '?';

    // Top-left rank
    const rank = svgEl('text', {
      x: 3, y: 13, class: `card-rank ${cls}`, 'font-size': 11,
      'font-family': 'Consolas, monospace', 'font-weight': '700'
    }, card.rank);
    g.appendChild(rank);

    // Center suit
    const suit = svgEl('text', {
      x: CARD_W / 2, y: CARD_H / 2 + 5,
      class: `card-suit ${cls}`,
      'text-anchor': 'middle', 'font-size': 16
    }, suitChar);
    g.appendChild(suit);
  }

  parent.appendChild(g);
  return g;
}

/**
 * Position seats evenly around an ellipse.
 * Returns array of {cx, cy} for each seat index.
 */
function seatPositions(n, cx, cy, rx, ry) {
  const positions = [];
  const startAngle = -Math.PI / 2; // top center
  for (let i = 0; i < n; i++) {
    const angle = startAngle + (2 * Math.PI * i) / n;
    positions.push({
      cx: Math.round(cx + rx * Math.cos(angle)),
      cy: Math.round(cy + ry * Math.sin(angle)),
    });
  }
  return positions;
}

/**
 * Draw a seat at (cx, cy).
 */
function drawSeat(parent, seat, cx, cy, isActionOn) {
  const g = svgEl('g', { class: 'seat-group' });

  const status = seat.status || 'active';
  const isFolded = status === 'folded' || status === 'out';
  const isAllIn  = status === 'all_in' || status === 'allin';

  let ringClass = 'seat-ring';
  if (isActionOn) ringClass += ' active';
  else if (isFolded) ringClass += ' folded';
  else if (isAllIn)  ringClass += ' allin';

  // Seat background box
  const boxW = 90, boxH = 62;
  const bx = cx - boxW / 2, by = cy - boxH / 2;

  const rect = svgEl('rect', {
    x: bx, y: by, width: boxW, height: boxH, rx: 8, ry: 8, class: ringClass
  });
  g.appendChild(rect);

  // Seat label
  const label = svgEl('text', {
    x: cx, y: by + 13, class: 'seat-label',
    'text-anchor': 'middle', 'font-size': 10
  }, seat.label || `Seat ${seat.index}`);
  g.appendChild(label);

  // Stack
  const stack = svgEl('text', {
    x: cx, y: by + 26, class: 'seat-stack',
    'text-anchor': 'middle', 'font-size': 11
  }, `$${seat.stack ?? 0}`);
  g.appendChild(stack);

  // Status badge (fold/all-in)
  if (isFolded) {
    const badge = svgEl('text', {
      x: cx, y: by + 38, class: 'seat-status',
      'text-anchor': 'middle', 'font-size': 9, fill: '#888'
    }, 'FOLDED');
    g.appendChild(badge);
  } else if (isAllIn) {
    const badge = svgEl('text', {
      x: cx, y: by + 38, class: 'seat-status',
      'text-anchor': 'middle', 'font-size': 9, fill: '#e63946'
    }, 'ALL-IN');
    g.appendChild(badge);
  }

  // Hole cards (small, below seat box)
  const cards = seat.holeCards || [];
  const numCards = Math.max(cards.length, 2); // always show 2 slots minimum
  const cardSpacing = CARD_W + 3;
  const totalCardsW = numCards * CARD_W + (numCards - 1) * 3;
  const cardStartX = cx - totalCardsW / 2;
  const cardY = by + boxH + 3;

  for (let i = 0; i < numCards; i++) {
    const cardCode = cards[i] || null;
    const showBack = !cardCode && !isFolded;
    drawCard(g, cardStartX + i * cardSpacing, cardY, showBack ? undefined : cardCode);
  }

  // Current bet chip
  if (seat.currentBet && seat.currentBet > 0 && !isFolded) {
    const chipG = svgEl('g');
    const betCx = cx + boxW / 2 - 4;
    const betCy = cy;
    const chip = svgEl('circle', { cx: betCx, cy: betCy, r: 12, class: 'bet-chip' });
    chipG.appendChild(chip);
    const betLbl = svgEl('text', {
      x: betCx, y: betCy + 3,
      class: 'bet-amount', 'text-anchor': 'middle', 'font-size': 8
    }, seat.currentBet > 999 ? `${Math.round(seat.currentBet / 1000)}k` : String(seat.currentBet));
    chipG.appendChild(betLbl);
    g.appendChild(chipG);
  }

  parent.appendChild(g);
}

/**
 * Draw the community cards centered on the table.
 */
function drawCommunity(parent, community, cx, cy) {
  const cards = community || [];
  const numSlots = 5;
  const spacing = CARD_W + 5;
  const totalW = numSlots * CARD_W + (numSlots - 1) * 5;
  const startX = cx - totalW / 2;
  const y = cy - CARD_H / 2;

  for (let i = 0; i < numSlots; i++) {
    const code = cards[i];
    if (!code) {
      // Empty slot
      const slot = svgEl('rect', {
        x: startX + i * spacing, y,
        width: CARD_W, height: CARD_H, rx: 3,
        class: 'community-slot'
      });
      parent.appendChild(slot);
    } else {
      drawCard(parent, startX + i * spacing, y, code);
    }
  }
}

/**
 * Draw the pot display below community cards.
 */
function drawPot(parent, pot, cx, cy) {
  if (!pot) return;
  const total = pot.total ?? pot.main ?? 0;
  const text = `POT: $${total}`;

  const bg = svgEl('rect', {
    x: cx - 55, y: cy - 11, width: 110, height: 20,
    rx: 6, class: 'pot-bg'
  });
  parent.appendChild(bg);

  const lbl = svgEl('text', {
    x: cx, y: cy + 4, class: 'pot-lbl',
    'text-anchor': 'middle', 'font-size': 12
  }, text);
  parent.appendChild(lbl);
}

/**
 * Draw the dealer button near a seat.
 */
function drawDealerBtn(parent, sx, sy) {
  const g = svgEl('g');
  // offset to upper-right of seat
  const bx = sx + 36, by = sy - 26;
  const circle = svgEl('circle', { cx: bx, cy: by, r: 10, class: 'dealer-btn' });
  g.appendChild(circle);
  const lbl = svgEl('text', {
    x: bx, y: by + 4, class: 'dealer-lbl',
    'text-anchor': 'middle', 'font-size': 9
  }, 'D');
  g.appendChild(lbl);
  parent.appendChild(g);
}

/**
 * Draw the green oval poker table.
 */
function drawTable(parent, vw, vh) {
  const cx = vw / 2, cy = vh / 2;
  const rx = vw * 0.42, ry = vh * 0.38;

  // Rail (outer border)
  const rail = svgEl('ellipse', {
    cx, cy,
    rx: rx + 16, ry: ry + 14,
    class: 'felt-outer'
  });
  parent.appendChild(rail);

  // Felt surface
  const felt = svgEl('ellipse', {
    cx, cy, rx, ry,
    class: 'felt-inner'
  });
  parent.appendChild(felt);

  // Inner highlight ring
  const inner = svgEl('ellipse', {
    cx, cy,
    rx: rx - 14, ry: ry - 12,
    fill: 'none',
    stroke: 'rgba(255,255,255,.04)',
    'stroke-width': 1
  });
  parent.appendChild(inner);
}

/**
 * Main render function.
 * @param {SVGElement} svg
 * @param {Object} state - session state JSON
 */
export function renderTable(svg, state) {
  // Clear
  while (svg.firstChild) svg.removeChild(svg.firstChild);

  const vw = 800, vh = 600;
  const cx = vw / 2, cy = vh / 2;

  // Table felt
  drawTable(svg, vw, vh);

  if (!state) return;

  const seats = state.seats || [];
  const n = seats.length;
  const rxSeat = vw * 0.36, rySeat = vh * 0.31;
  const positions = seatPositions(n, cx, cy, rxSeat, rySeat);

  // Community cards
  drawCommunity(svg, state.community, cx, cy - 30);

  // Pot
  drawPot(svg, state.pot, cx, cy + 34);

  // Street label in center top
  if (state.street) {
    const streetLbl = svgEl('text', {
      x: cx, y: cy - 75,
      fill: 'rgba(255,255,255,.4)',
      'text-anchor': 'middle',
      'font-size': 11,
      'text-transform': 'uppercase',
      'letter-spacing': 2
    }, state.street.toUpperCase());
    svg.appendChild(streetLbl);
  }

  // Seats
  seats.forEach((seat, i) => {
    const pos = positions[i];
    const isAction = seat.index === state.actionOn;
    drawSeat(svg, seat, pos.cx, pos.cy, isAction);

    // Dealer button
    if (seat.index === state.dealerSeat) {
      drawDealerBtn(svg, pos.cx, pos.cy);
    }
  });
}
