/* global React, window */
const { useState, useEffect, useMemo, useRef } = React;

/* ---------- Icons (minimalist line strokes) ---------- */
function Icon({ d, size = 14, sw = 1.6, fill = "none" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke="currentColor" strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
      <path d={d} />
    </svg>
  );
}
const I = {
  home:    "M3 11l9-8 9 8M5 10v10h14V10",
  series:  "M4 6h16M4 12h16M4 18h10",
  events:  "M4 5h16v14H4zM4 9h16M9 5v14",
  flights: "M3 12h18M3 6h18M3 18h12",
  tables:  "M3 5h18v14H3zM3 12h18M9 5v14M15 5v14",
  players: "M16 14a4 4 0 10-8 0M12 11a3 3 0 100-6 3 3 0 000 6zM3 21a7 7 0 0118 0",
  search:  "M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.3-4.3",
  star:    "M12 3l2.9 6 6.6.6-5 4.6 1.5 6.6L12 17.5 5.9 20.8 7.5 14.2 2.5 9.6l6.6-.6z",
  plus:    "M12 5v14M5 12h14",
  chev:    "M9 6l6 6-6 6",
  back:    "M15 6l-6 6 6 6",
  cog:     "M12 8v0a4 4 0 100 8 4 4 0 000-8zM12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1",
  bell:    "M15 17h5l-1.4-2.4A6 6 0 0118 12V9a6 6 0 10-12 0v3a6 6 0 01-.6 2.6L4 17h5M9 17a3 3 0 006 0",
  power:   "M12 2v10M5.6 7.4a9 9 0 1012.8 0",
  mail:    "M3 7l9 6 9-6M3 7v10h18V7H3z",
  lock:    "M5 11h14v10H5zM8 11V8a4 4 0 018 0v3",
  filter:  "M3 5h18l-7 9v6l-4-2v-4z",
  eye:     "M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 9a3 3 0 100 6 3 3 0 000-6z",
  bolt:    "M13 2L3 14h8l-1 8 10-12h-8z",
  arrow:   "M5 12h14M13 5l7 7-7 7",
};

/* ---------- TopBar ---------- */
function TopBar({ tweaks, clock, onToggleRail }) {
  return (
    <div className="topbar">
      <div className="topbar-brand" onClick={onToggleRail} style={{cursor:"pointer"}}>
        <div className="brand-mark">E</div>
        <span>EBS LOBBY</span>
      </div>
      <div className="topbar-cluster">
        <div><span className="lbl">SHOW</span><span className="val">WPS · EU 2026</span></div>
        <div className="topbar-divider" />
        <div><span className="lbl">FLIGHT</span><span className="val">Day2</span></div>
        <div className="topbar-divider" />
        <div><span className="lbl">LEVEL</span><span className="val">L17 · 6,000 / 12,000</span></div>
        <div className="topbar-divider" />
        <div><span className="lbl">NEXT</span><span className="val">22:48</span></div>
      </div>
      <div className="topbar-right">
        <button className="cc-pill"><span className="pulse" /> Active CC · 3</button>
        <span className="mono" style={{fontSize:11, color:"var(--rail-ink-dim)"}}>{clock}</span>
        <span style={{color:"var(--rail-line)"}}>|</span>
        <div className="user-pill"><div className="av">JK</div><span>J. Kim · Admin</span></div>
      </div>
    </div>
  );
}

/* ---------- Side rail ---------- */
function Rail({ screen, setScreen, collapsed }) {
  const items = [
    { id: "series",  label: "Series",  icon: I.home,    badge: 4 },
    { id: "events",  label: "Events",  icon: I.events,  badge: 95, group: "WPS · EU 2026" },
    { id: "flights", label: "Flights", icon: I.flights, badge: 8 },
    { id: "tables",  label: "Tables",  icon: I.tables,  badge: 124, live: true },
    { id: "players", label: "Players", icon: I.players, badge: 918 },
  ];
  return (
    <aside className="rail">
      <div className="rail-section">Navigate</div>
      {items.slice(0,1).map(it => (
        <RailItem key={it.id} it={it} active={screen === it.id} onClick={() => setScreen(it.id)} />
      ))}
      <div className="rail-section">WPS · EU 2026 — Event #5</div>
      {items.slice(1).map(it => (
        <RailItem key={it.id} it={it} active={screen === it.id} onClick={() => setScreen(it.id)} />
      ))}
      <div className="rail-section">Tools</div>
      <div className={"rail-item" + (screen==="hands" ? " active" : "")} onClick={() => setScreen("hands")}>
        <span className="ic"><Icon d={I.bolt} /></span><span className="lbl">Hand History</span><span className="badge">142</span>
      </div>
      <div className={"rail-item" + (screen==="alerts" ? " active" : "")} onClick={() => setScreen("alerts")}>
        <span className="ic"><Icon d={I.bell} /></span><span className="lbl">Alerts</span><span className="badge">4</span>
      </div>
      <div className={"rail-item" + (screen==="settings" ? " active" : "")} onClick={() => setScreen("settings")}>
        <span className="ic"><Icon d={I.cog} /></span><span className="lbl">Settings</span>
      </div>
      <div className="rail-spacer" />
      <div className="rail-foot"><span className="ver">EBS v5.0.0</span><span>●</span></div>
    </aside>
  );
}
function RailItem({ it, active, onClick }) {
  return (
    <div className={"rail-item" + (active ? " active" : "")} onClick={onClick}>
      <span className="ic"><Icon d={it.icon} /></span>
      <span className="lbl">{it.label}</span>
      {it.badge != null && <span className="badge">{it.badge.toLocaleString()}</span>}
    </div>
  );
}

/* ---------- Breadcrumb ---------- */
function Breadcrumb({ trail, setScreen }) {
  return (
    <div className="bc-bar">
      <div className="bc">
        {trail.map((c, i) => (
          <React.Fragment key={i}>
            {i > 0 && <span className="sep"><Icon d={I.chev} size={11} /></span>}
            <span
              className={"crumb" + (i === trail.length - 1 ? " cur" : "")}
              onClick={() => c.go && setScreen(c.go)}
            >{c.label}</span>
          </React.Fragment>
        ))}
      </div>
      <div className="bc-actions">
        <span className="kbd">⌘K</span>
        <span className="dim">to jump</span>
      </div>
    </div>
  );
}

window.EBS_UI = { TopBar, Rail, Breadcrumb, Icon, I };
