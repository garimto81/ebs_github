(() => {
  "use strict";

  const CHAT_CHANNELS = ["room:design", "room:blocker", "room:handoff"];
  const PANEL_BY_CHANNEL = {
    "room:design": document.getElementById("msgs-design"),
    "room:blocker": document.getElementById("msgs-blocker"),
    "room:handoff": document.getElementById("msgs-handoff"),
    "trace": document.getElementById("msgs-trace"),
  };
  const SELF = "user";  // Web UI 는 항상 user 시점

  function escapeHtml(s) {
    return s.replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;",
      '"': "&quot;", "'": "&#39;"
    }[c]));
  }

  function highlightMentions(body, selfMention) {
    return escapeHtml(body).replace(/@([A-Za-z][\w-]*)/g, (_, name) => {
      const cls = name === selfMention ? "mention-self" : "mention";
      return `<span class="${cls}">@${name}</span>`;
    });
  }

  function renderMessage(panel, event) {
    const p = event.payload || {};
    const from = p.from || event.source || "unknown";
    const kind = p.kind || "msg";
    const ts = (p.ts || event.ts || "").slice(11, 16);
    const isReply = kind === "reply" || p.reply_to != null;

    const el = document.createElement("div");
    el.className = `msg from-${from} kind-${kind}${isReply ? " reply" : ""}`;
    el.dataset.seq = event.seq;
    el.innerHTML =
      `<span class="ts">${ts}</span>` +
      `<span class="from">[${escapeHtml(from)}]</span>` +
      (isReply ? `<span class="reply-ref">re: ${p.reply_to}</span> ` : "") +
      highlightMentions(p.body || "", SELF);

    const stickyBottom =
      panel.scrollHeight - panel.scrollTop - panel.clientHeight < 40;
    panel.appendChild(el);
    if (stickyBottom) panel.scrollTop = panel.scrollHeight;
  }

  function renderTrace(event) {
    const panel = PANEL_BY_CHANNEL.trace;
    const topic = event.topic;
    const source = event.source || "?";
    const ts = (event.ts || "").slice(11, 16);
    const payloadStr = JSON.stringify(event.payload || {}).slice(0, 120);

    const el = document.createElement("div");
    el.className = "msg kind-system";
    el.innerHTML =
      `<span class="ts">${ts}</span>` +
      `<span class="from">${escapeHtml(topic)}</span>` +
      `<span style="color:var(--muted)">(${escapeHtml(source)})</span> ` +
      `<span style="color:var(--muted)">${escapeHtml(payloadStr)}</span>`;
    panel.appendChild(el);
    panel.scrollTop = panel.scrollHeight;
  }

  function dispatchEvent(event) {
    const topic = event.topic || "";
    if (topic.startsWith("chat:")) {
      const channel = topic.slice("chat:".length);
      const panel = PANEL_BY_CHANNEL[channel];
      if (panel) renderMessage(panel, event);
    } else {
      renderTrace(event);
    }
  }

  async function loadHistory(channel) {
    const panel = PANEL_BY_CHANNEL[channel];
    if (!panel) return;
    try {
      const r = await fetch(
        `/chat/history?channel=${encodeURIComponent(channel)}&limit=50`
      );
      const data = await r.json();
      for (const event of data.events || []) renderMessage(panel, event);
    } catch (e) {
      console.warn("history load failed", channel, e);
    }
  }

  async function refreshPeers() {
    try {
      const r = await fetch("/chat/peers?active=true");
      const data = await r.json();
      const sources = (data.peers || []).map(p => p.source);
      document.getElementById("peers").textContent =
        "active: " + sources.join(" ");
      window.__activePeers = sources;
    } catch (e) {
      window.__activePeers = window.__activePeers || [];
    }
  }

  function connectSSE() {
    const banner = document.getElementById("broker-state");
    const src = new EventSource("/chat/stream?from_seq=0");
    src.addEventListener("chat", (e) => {
      try { dispatchEvent(JSON.parse(e.data)); }
      catch { /* ignore malformed */ }
    });
    src.addEventListener("trace", (e) => {
      try { renderTrace(JSON.parse(e.data)); }
      catch { /* ignore */ }
    });
    src.addEventListener("error", (e) => {
      banner.textContent = "broker: offline (retrying...)";
      banner.style.color = "var(--user)";
    });
    src.onopen = () => {
      banner.textContent = "broker: online";
      banner.style.color = "";
    };
  }

  // Composer Enter handler
  document.querySelectorAll(".composer textarea").forEach((ta) => {
    ta.addEventListener("keydown", async (e) => {
      const dd = ta.parentElement.querySelector(".autocomplete");
      if (e.key === "Enter" && !e.shiftKey) {
        if (dd && !dd.hidden) return;  // autocomplete 가 처리
        e.preventDefault();
        const channel = ta.dataset.channel;
        const body = ta.value.trim();
        if (!body) return;
        try {
          await fetch("/chat/send", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({channel, body}),
          });
          ta.value = "";
        } catch (err) {
          console.error("send failed", err);
        }
      }
    });
  });

  // Init
  (async () => {
    await Promise.all(CHAT_CHANNELS.map(loadHistory));
    await refreshPeers();
    setInterval(refreshPeers, 5000);
    connectSSE();
  })();

  // ──────────────── @ Autocomplete ────────────────

  function activePeers() {
    return [...(window.__activePeers || []), "user", "all"];
  }

  function showAutocomplete(textarea, dropdown, query) {
    const peers = activePeers().filter(
      p => p.toLowerCase().startsWith(query.toLowerCase())
    );
    if (peers.length === 0) {
      dropdown.hidden = true;
      return;
    }
    dropdown.innerHTML = peers
      .map((p, i) => `<div class="item${i === 0 ? " active" : ""}" data-peer="${escapeHtml(p)}">@${escapeHtml(p)}</div>`)
      .join("");
    dropdown.hidden = false;
  }

  function applyAutocomplete(textarea, peer) {
    const val = textarea.value;
    const caret = textarea.selectionStart;
    const atIdx = val.lastIndexOf("@", caret - 1);
    if (atIdx < 0) return;
    const before = val.slice(0, atIdx);
    const after = val.slice(caret);
    const inserted = `@${peer} `;
    textarea.value = before + inserted + after;
    const newCaret = atIdx + inserted.length;
    textarea.setSelectionRange(newCaret, newCaret);
    textarea.focus();
  }

  document.querySelectorAll(".composer").forEach((composer) => {
    const ta = composer.querySelector("textarea");
    const dropdown = composer.querySelector(".autocomplete");

    ta.addEventListener("input", () => {
      const caret = ta.selectionStart;
      const val = ta.value;
      const atIdx = val.lastIndexOf("@", caret - 1);
      if (atIdx < 0) {
        dropdown.hidden = true;
        return;
      }
      const between = val.slice(atIdx + 1, caret);
      if (/\s/.test(between)) {
        dropdown.hidden = true;
        return;
      }
      showAutocomplete(ta, dropdown, between);
    });

    ta.addEventListener("keydown", (e) => {
      if (dropdown.hidden) return;
      const items = [...dropdown.querySelectorAll(".item")];
      const activeIdx = items.findIndex(it => it.classList.contains("active"));
      if (e.key === "ArrowDown") {
        e.preventDefault();
        const next = (activeIdx + 1) % items.length;
        items[activeIdx]?.classList.remove("active");
        items[next].classList.add("active");
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        const prev = (activeIdx - 1 + items.length) % items.length;
        items[activeIdx]?.classList.remove("active");
        items[prev].classList.add("active");
      } else if (e.key === "Enter") {
        e.preventDefault();
        const sel = items[activeIdx >= 0 ? activeIdx : 0];
        applyAutocomplete(ta, sel.dataset.peer);
        dropdown.hidden = true;
      } else if (e.key === "Escape") {
        dropdown.hidden = true;
      }
    });

    dropdown.addEventListener("click", (e) => {
      const item = e.target.closest(".item");
      if (item) {
        applyAutocomplete(ta, item.dataset.peer);
        dropdown.hidden = true;
      }
    });
  });
})();
