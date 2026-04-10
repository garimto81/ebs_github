/**
 * timeline.js — Playback timeline controls.
 */

let _seekCallback = null;
let _currentState = null;

const tlFirst  = () => document.getElementById('tl-first');
const tlPrev   = () => document.getElementById('tl-prev');
const tlNext   = () => document.getElementById('tl-next');
const tlLast   = () => document.getElementById('tl-last');
const tlSlider = () => document.getElementById('tl-slider');
const tlLabel  = () => document.getElementById('tl-label');
const replayBadge = () => document.getElementById('tl-replay-badge');

/**
 * Initialize timeline controls.
 * @param {function} seekCallback - called with target cursor value
 */
export function initTimeline(seekCallback) {
  _seekCallback = seekCallback;

  tlFirst().addEventListener('click', () => seek(0));
  tlPrev().addEventListener('click',  () => {
    const cur = _currentState?.cursor ?? 0;
    seek(Math.max(0, cur - 1));
  });
  tlNext().addEventListener('click', () => {
    const cur = _currentState?.cursor ?? 0;
    const max = _currentState?.eventCount ?? 0;
    seek(Math.min(max, cur + 1));
  });
  tlLast().addEventListener('click', () => {
    seek(_currentState?.eventCount ?? 0);
  });

  tlSlider().addEventListener('input', () => {
    seek(parseInt(tlSlider().value) || 0);
  });
}

function seek(cursor) {
  _seekCallback?.(cursor);
}

/**
 * Update timeline display from state.
 * @param {Object} state - session state
 */
export function updateTimeline(state) {
  _currentState = state;

  const cursor = state?.cursor ?? 0;
  const total  = state?.eventCount ?? 0;

  tlSlider().max   = total;
  tlSlider().value = cursor;
  tlLabel().textContent = `${cursor}/${total}`;

  const isReplay = cursor < total;
  replayBadge().style.display = isReplay ? 'inline-block' : 'none';

  // Disable buttons at limits
  tlFirst().disabled = cursor === 0;
  tlPrev().disabled  = cursor === 0;
  tlNext().disabled  = cursor >= total;
  tlLast().disabled  = cursor >= total;
}
