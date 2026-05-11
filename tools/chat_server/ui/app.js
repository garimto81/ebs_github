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
      if (e.key === "Enter" && !e.shiftKey) {
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
})();
