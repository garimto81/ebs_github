/**
 * event-log.js — Render event log list with cursor highlighting.
 */

/**
 * Render the event log.
 * @param {Object} state - session state
 * @param {function} seekCallback - called with cursor index when user clicks an event
 */
export function renderLog(state, seekCallback) {
  const list = document.getElementById('event-list');
  const badge = document.getElementById('lbl-event-count');
  if (!list) return;

  const log = state?.log || [];
  const cursor = state?.cursor ?? 0;

  if (badge) {
    badge.textContent = `${log.length} event${log.length !== 1 ? 's' : ''}`;
  }

  // Partial update: only rebuild if log length changed to avoid full re-render flicker
  const existing = list.children;
  if (existing.length !== log.length) {
    list.innerHTML = '';
    log.forEach((entry, i) => {
      const li = buildItem(entry, i, cursor, seekCallback);
      list.appendChild(li);
    });
  } else {
    // Just update highlight
    Array.from(existing).forEach((li, i) => {
      li.classList.toggle('current', i + 1 === cursor);
    });
  }

  // Scroll current item into view
  const currentItem = list.querySelector('li.current');
  if (currentItem) {
    currentItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }
}

function buildItem(entry, index, cursor, seekCallback) {
  const li = document.createElement('li');
  li.classList.toggle('current', index + 1 === cursor);

  const idxSpan = document.createElement('span');
  idxSpan.className = 'log-idx';
  idxSpan.textContent = String(index + 1).padStart(3, ' ');

  const typeSpan = document.createElement('span');
  typeSpan.className = 'log-type';
  typeSpan.textContent = entry.type || '?';

  const descSpan = document.createElement('span');
  descSpan.className = 'log-desc';
  descSpan.textContent = entry.description || '';

  li.appendChild(idxSpan);
  li.appendChild(typeSpan);
  li.appendChild(descSpan);

  li.title = entry.description || entry.type || '';
  li.addEventListener('click', () => {
    seekCallback?.(index + 1);
  });

  return li;
}
