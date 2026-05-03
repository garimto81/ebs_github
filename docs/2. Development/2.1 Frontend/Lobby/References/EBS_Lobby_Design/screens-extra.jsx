/* global React, window */
const { useState, useMemo } = React;
const { Icon, I } = window.EBS_UI;

/* ============== HAND HISTORY ============== */
const HANDS = [
  { id: 47, game: "O Hi-Lo", players: 7, winner: "P. Nguyen", pot: 24800, time: "14:32", showdown: true, big: true,
    blinds: "100/200", limit: "Limit", table: "Day2-#071",
    board: [{r:"A",s:"♠",c:"k"},{r:"7",s:"♦",c:"r"},{r:"3",s:"♠",c:"k"},{r:"K",s:"♣",c:"k"},{r:"2",s:"♥",c:"r"}],
    seats: [
      { seat:1, name:"P. Nguyen", hole:"A♥ 2♦ 3♣ 5♠", action:"Bet/Call", result:"Hi+Lo",  pnl:+18400, won:true },
      { seat:3, name:"R. Chen",   hole:"K♥ Q♦ J♣ T♠", action:"Call/Fold", result:"—",      pnl:-4200 },
      { seat:5, name:"J. Smith",  hole:"A♣ 4♥ 6♦ 8♠", action:"Raise/Call",result:"2nd Lo", pnl:-6400 },
      { seat:7, name:"M. Lee",    hole:"—",            action:"Fold",     result:"—",      pnl:-200 },
    ],
    phases: [{n:"Preflop",p:1400},{n:"Flop",p:6200},{n:"Turn",p:14600},{n:"River",p:24800,active:true}],
  },
  { id: 46, game: "O Hi-Lo", players: 8, winner: "R. Chen",     pot: 18200, time: "14:28", showdown: true,  big: false },
  { id: 45, game: "O Hi-Lo", players: 7, winner: "—",           pot:  1200, time: "14:25", showdown: false, big: false },
  { id: 44, game: "Holdem",  players: 8, winner: "J. Smith",    pot: 42600, time: "14:18", showdown: true,  big: true },
  { id: 43, game: "Holdem",  players: 6, winner: "M. Lee",      pot: 15400, time: "14:12", showdown: true,  big: false },
  { id: 42, game: "Razz",    players: 7, winner: "A. Patel",    pot:  8800, time: "14:06", showdown: true,  big: false },
  { id: 41, game: "Holdem",  players: 8, winner: "P. Nguyen",   pot: 31200, time: "14:01", showdown: true,  big: true },
  { id: 40, game: "Stud",    players: 6, winner: "K. Volkov",   pot:  6400, time: "13:55", showdown: true,  big: false },
  { id: 39, game: "Holdem",  players: 8, winner: "—",           pot:   900, time: "13:51", showdown: false, big: false },
  { id: 38, game: "PLO",     players: 7, winner: "J. Smith",    pot: 12100, time: "13:46", showdown: true,  big: false },
];

function HandHistoryScreen() {
  const [filter, setFilter] = useState("all");
  const [selected, setSelected] = useState(47);
  const filtered = HANDS.filter(h => {
    if (filter === "showdown") return h.showdown;
    if (filter === "big")      return h.big;
    return true;
  });
  const detail = HANDS.find(h => h.id === selected);

  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Table</div><div className="k-v" style={{fontSize:14, fontFamily:"var(--ui)"}}>Day2-#071 ★</div><div className="k-sub">Featured · LIVE</div></div>
        <div className="kpi"><div className="k-l">Hands Played</div><div className="k-v">142</div><div className="k-sub">since L1</div></div>
        <div className="kpi"><div className="k-l">Showdowns</div><div className="k-v">38</div><div className="k-sub">26.8%</div></div>
        <div className="kpi"><div className="k-l">Biggest Pot</div><div className="k-v">142,400</div><div className="k-sub">hand #18</div></div>
        <div className="kpi"><div className="k-l">Avg Pot</div><div className="k-v">9,820</div><div className="k-sub">last 20 hands</div></div>
      </div>

      <div className="toolbar">
        <div className="left">
          <div className="field"><span className="ic"><Icon d={I.search}/></span><input placeholder="Search hand #, player…" /></div>
          <div className="seg">
            <button className={filter==="all"?"on":""}      onClick={()=>setFilter("all")}>All Hands</button>
            <button className={filter==="showdown"?"on":""} onClick={()=>setFilter("showdown")}>Showdown Only</button>
            <button className={filter==="big"?"on":""}      onClick={()=>setFilter("big")}>Big Pots</button>
          </div>
        </div>
        <div className="right">
          <button className="btn ghost sm">Export Hand</button>
          <button className="btn ghost sm">Replay ▶</button>
        </div>
      </div>

      <div style={{display:"flex", flex:1, minHeight:0, overflow:"hidden"}}>
        <div style={{flex:"1.1", minWidth:0, overflow:"auto", borderRight:"1px solid var(--line)"}}>
          <table className="dtable">
            <thead>
              <tr>
                <th style={{width:70}}>Hand #</th>
                <th style={{width:90}}>Game</th>
                <th style={{width:70}} className="ctr">Players</th>
                <th>Winner</th>
                <th style={{width:90}} className="num">Pot</th>
                <th style={{width:60}} className="ctr">Time</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(h => (
                <tr key={h.id} className={h.id===selected ? "feat" : ""} onClick={()=>setSelected(h.id)}>
                  <td className="mono"><b>#{h.id}</b></td>
                  <td className="mono">{h.game}</td>
                  <td className="ctr mono">{h.players}</td>
                  <td>{h.winner === "—" ? <span className="muted">—</span> : <b style={{color:"var(--live-ink)"}}>{h.winner}</b>}</td>
                  <td className="num mono"><b>{h.pot.toLocaleString()}</b></td>
                  <td className="ctr mono dim">{h.time}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div style={{flex:"0.95", minWidth:380, overflow:"auto", padding:"18px 22px"}}>
          {detail && detail.board && (
            <>
              <div style={{display:"flex", justifyContent:"space-between", alignItems:"baseline", marginBottom:14}}>
                <div>
                  <div style={{fontSize:11, letterSpacing:"0.10em", textTransform:"uppercase", color:"var(--ink-4)", marginBottom:4}}>Hand #{detail.id} · {detail.game} ({detail.limit})</div>
                  <div style={{fontSize:18, fontWeight:600}}>{detail.table} · Pot {detail.pot.toLocaleString()}</div>
                  <div className="dim mono" style={{fontSize:12, marginTop:2}}>Blinds {detail.blinds} · {detail.players} players · {detail.time}</div>
                </div>
                <button className="btn live sm">Replay ▶</button>
              </div>

              <div style={{marginBottom:18}}>
                <div style={{fontSize:10, letterSpacing:"0.12em", textTransform:"uppercase", color:"var(--ink-4)", marginBottom:8}}>Board</div>
                <div style={{display:"flex", gap:6}}>
                  {detail.board.map((c,i) => (
                    <div key={i} style={{
                      width:42, height:58, border:"1px solid var(--line-strong)", borderRadius:5,
                      background:"var(--bg)", display:"grid", placeItems:"center",
                      fontFamily:"var(--mono)", fontSize:18, fontWeight:600,
                      color: c.c==="r" ? "var(--danger)" : "var(--ink)",
                      boxShadow:"0 1px 2px oklch(0.10 0.01 80 / 0.06)"
                    }}>{c.r}{c.s}</div>
                  ))}
                </div>
              </div>

              <div style={{marginBottom:18}}>
                <div style={{fontSize:10, letterSpacing:"0.12em", textTransform:"uppercase", color:"var(--ink-4)", marginBottom:8}}>Players</div>
                <table className="dtable" style={{fontSize:11.5}}>
                  <thead>
                    <tr>
                      <th style={{width:36}} className="ctr">Seat</th>
                      <th>Player</th>
                      <th style={{width:120}}>Hole</th>
                      <th style={{width:90}}>Action</th>
                      <th style={{width:70}}>Result</th>
                      <th style={{width:80}} className="num">P&amp;L</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.seats.map(s => (
                      <tr key={s.seat} className={s.won ? "feat" : ""}>
                        <td className="ctr mono">{s.seat}</td>
                        <td><b>{s.name}</b>{s.won && <span className="star" style={{marginLeft:6}}>★</span>}</td>
                        <td className="mono">{s.hole}</td>
                        <td className="dim">{s.action}</td>
                        <td><b style={{color: s.won ? "var(--live-ink)" : "var(--ink-2)"}}>{s.result}</b></td>
                        <td className="num mono"><b style={{color: s.pnl > 0 ? "var(--live-ink)" : "var(--danger-ink)"}}>{s.pnl > 0 ? "+" : ""}{s.pnl.toLocaleString()}</b></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div>
                <div style={{fontSize:10, letterSpacing:"0.12em", textTransform:"uppercase", color:"var(--ink-4)", marginBottom:8}}>Action Sequence</div>
                <div style={{display:"flex", gap:6}}>
                  {detail.phases.map((p,i) => (
                    <div key={i} style={{
                      flex:1, padding:"8px 10px",
                      border: p.active ? "1px solid var(--ink)" : "1px solid var(--line)",
                      background: p.active ? "var(--feat-bg)" : "var(--bg)",
                      borderRadius:4, textAlign:"center"
                    }}>
                      <div style={{fontSize:10.5, fontWeight:600, color:"var(--ink)"}}>{p.n}</div>
                      <div style={{fontSize:10, color:"var(--ink-3)", fontFamily:"var(--mono)", marginTop:2}}>{p.p.toLocaleString()}</div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </>
  );
}

/* ============== ALERTS ============== */
const ALERTS = [
  { id: 1, sev: "err",  ts: "14:32:08", src: "RFID",   table: "Day2-#072",
    title: "RFID reader desynchronized",
    body: "Deck integrity drifted to 0/52 mid-hand. Operator C is paused; pairing required before next deal.",
    cta: "Resync RFID", unread: true },
  { id: 2, sev: "warn", ts: "14:30:41", src: "Seat",   table: "Day2-#069",
    title: "Seat 9 elimination not confirmed",
    body: "Floor reported elimination 4m ago — chip count still posted to chip-bag. Confirm bust to release seat.",
    cta: "Mark Eliminated", unread: true },
  { id: 3, sev: "info", ts: "14:28:00", src: "Level",  table: null,
    title: "Level 18 starts in 22:48",
    body: "Auto-balance will run at L18 break. 4 tables flagged short (≤6 seats).",
    cta: "Preview Balance" },
  { id: 4, sev: "warn", ts: "14:14:22", src: "CC",     table: "Day2-#075",
    title: "Operator B idle > 8 min",
    body: "Station #23 streaming idle since 14:06. Reassign operator or pause station.",
    cta: "Reassign" },
  { id: 5, sev: "info", ts: "13:58:11", src: "Stream", table: "Day2-#071",
    title: "NDI feed promoted to marquee",
    body: "Producer pushed Day2-#071 to broadcast A. CC operator notified.", read: true },
  { id: 6, sev: "info", ts: "13:42:55", src: "System", table: null,
    title: "Auto-seating refilled 12 seats",
    body: "Waitlist reduced 24 → 12. Avg wait 3m.", read: true },
];

function AlertsScreen() {
  const [sev, setSev] = useState("all");
  const [src, setSrc] = useState("all");
  const list = ALERTS.filter(a => (sev==="all" || a.sev===sev) && (src==="all" || a.src===src));
  const cnt = { err: ALERTS.filter(a=>a.sev==="err").length,
                warn:ALERTS.filter(a=>a.sev==="warn").length,
                info:ALERTS.filter(a=>a.sev==="info").length };

  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Open</div><div className="k-v">{ALERTS.filter(a=>!a.read).length}</div><div className="k-sub">requires action</div></div>
        <div className="kpi"><div className="k-l">Errors</div><div className="k-v red">{cnt.err}</div><div className="k-sub">live tables</div></div>
        <div className="kpi"><div className="k-l">Warnings</div><div className="k-v amber">{cnt.warn}</div><div className="k-sub">monitor</div></div>
        <div className="kpi"><div className="k-l">Info</div><div className="k-v">{cnt.info}</div><div className="k-sub">last 60min</div></div>
        <div className="kpi"><div className="k-l">MTTR</div><div className="k-v">2m 14s</div><div className="k-sub">today</div></div>
      </div>

      <div className="toolbar">
        <div className="left">
          <div className="seg">
            {["all","err","warn","info"].map(s => (
              <button key={s} className={sev===s?"on":""} onClick={()=>setSev(s)}>
                {s==="all"?"All":s==="err"?"Errors":s==="warn"?"Warnings":"Info"}
              </button>
            ))}
          </div>
          <div className="seg">
            {["all","RFID","Seat","CC","Level","Stream","System"].map(s => (
              <button key={s} className={src===s?"on":""} onClick={()=>setSrc(s)}>{s==="all"?"All sources":s}</button>
            ))}
          </div>
        </div>
        <div className="right">
          <button className="btn ghost sm">Mute 15m</button>
          <button className="btn ghost sm">Mark all read</button>
        </div>
      </div>

      <div style={{padding:"4px 0", overflow:"auto"}}>
        {list.map(a => (
          <div key={a.id} style={{
            display:"grid", gridTemplateColumns:"4px 90px 1fr auto",
            borderBottom:"1px solid var(--line-soft)",
            background: a.unread ? "var(--bg)" : "var(--bg-alt)",
          }}>
            <div style={{
              background:
                a.sev==="err"  ? "var(--danger)" :
                a.sev==="warn" ? "var(--warn)" :
                "var(--info)"
            }} />
            <div style={{padding:"14px 14px 14px 18px", fontFamily:"var(--mono)", fontSize:11, color:"var(--ink-3)"}}>
              <div style={{color:"var(--ink-2)"}}>{a.ts}</div>
              <div style={{marginTop:2, fontSize:10, letterSpacing:"0.08em", textTransform:"uppercase", color:"var(--ink-4)"}}>{a.src}</div>
            </div>
            <div style={{padding:"14px 16px", minWidth:0}}>
              <div style={{display:"block", marginBottom:4, lineHeight:1.4}}>
                {a.unread && <span style={{display:"inline-block", width:6, height:6, borderRadius:"50%", background:"var(--live)", marginRight:8, verticalAlign:"middle"}}/>}
                <b style={{fontSize:13}}>{a.title}</b>
                {a.table && <span className="mono dim" style={{fontSize:11, marginLeft:6}}>· {a.table}</span>}
              </div>
              <div className="dim" style={{fontSize:12, lineHeight:1.5, maxWidth:720, display:"block", clear:"both"}}>{a.body}</div>
            </div>
            <div style={{padding:"14px 18px", display:"flex", gap:6, alignItems:"center"}}>
              {a.cta && <button className={"btn sm " + (a.sev==="err" ? "primary" : "ghost")}>{a.cta}</button>}
              <button className="btn xs ghost">✕</button>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

/* ============== SETTINGS (BS-03 spec) ==============
   6 tabs per UI-03 spec:
   Outputs (13) / GFX (14) / Display (17) / Rules (11) / Stats (15) / Preferences (9)
   Common footer: [Reset to Default] [Cancel] [Save]
   Admin-only. LOCK/CONFIRM/FREE classification per Overview §3.3
=================================================== */

// ---- shared field renderers ----
function FieldRow({ label, classification, hint, children }) {
  // classification: "FREE" (immediate) | "CONFIRM" (next hand) | "LOCK" (disabled)
  const tagColor = classification === "LOCK" ? "var(--ink-4)"
                 : classification === "CONFIRM" ? "var(--warn)"
                 : "var(--live)";
  return (
    <div style={{
      display:"grid", gridTemplateColumns:"220px 1fr",
      gap:20, alignItems:"start", padding:"14px 0",
      borderBottom:"1px solid var(--line-soft)",
      opacity: classification === "LOCK" ? 0.5 : 1
    }}>
      <div>
        <div style={{fontSize:13, fontWeight:500, color:"var(--ink)", marginBottom:3}}>{label}</div>
        {classification && (
          <span className="mono" style={{
            fontSize:9, letterSpacing:"0.12em", color: tagColor,
            border:`1px solid ${tagColor}`, padding:"1px 5px", borderRadius:2
          }}>{classification}</span>
        )}
        {hint && <div className="dim" style={{fontSize:11, marginTop:4, lineHeight:1.4}}>{hint}</div>}
      </div>
      <div style={{display:"flex", flexDirection:"column", gap:8, alignSelf:"center"}}>{children}</div>
    </div>
  );
}

function SubGroup({ title, count, children }) {
  return (
    <div style={{marginBottom:32}}>
      <div style={{
        fontSize:11, letterSpacing:"0.16em", textTransform:"uppercase",
        color:"var(--ink-4)", marginBottom:6, display:"flex",
        alignItems:"center", gap:10
      }}>
        <span style={{color:"var(--ink-2)", fontWeight:600}}>{title}</span>
        {count != null && <span className="mono" style={{fontSize:10, color:"var(--ink-4)"}}>· {count}</span>}
        <span style={{flex:1, height:1, background:"var(--line)"}}/>
      </div>
      <div>{children}</div>
    </div>
  );
}

function Sel({ value, options, onChange }) {
  return (
    <select value={value} onChange={e=>onChange?.(e.target.value)} style={{
      background:"var(--bg)", border:"1px solid var(--line)", borderRadius:4,
      padding:"6px 10px", fontSize:12, color:"var(--ink)",
      fontFamily:"var(--ui)", minWidth:200, cursor:"pointer"
    }}>
      {options.map(o => <option key={o} value={o}>{o}</option>)}
    </select>
  );
}
function Sw({ on, onToggle }) {
  return (
    <button onClick={onToggle} style={{
      width:36, height:20, border:"0", borderRadius:999, padding:0,
      background: on ? "var(--live)" : "var(--line-strong)",
      position:"relative", cursor:"pointer", flex:"0 0 auto"
    }}>
      <span style={{
        position:"absolute", top:2, left: on ? 18 : 2, width:16, height:16, borderRadius:"50%",
        background:"#fff", transition:"left 120ms",
        boxShadow:"0 1px 2px oklch(0.10 0.01 80 / 0.30)"
      }}/>
    </button>
  );
}
function Slider({ value, min=0, max=1, step=0.01, suffix }) {
  return (
    <div style={{display:"flex", alignItems:"center", gap:10, maxWidth:300}}>
      <input type="range" min={min} max={max} step={step} defaultValue={value} style={{flex:1, accentColor:"var(--ink-2)"}}/>
      <span className="mono" style={{fontSize:11, color:"var(--ink-3)", minWidth:48, textAlign:"right"}}>
        {value}{suffix||""}
      </span>
    </div>
  );
}
function Inp({ value, width=200, mono=false, type="text" }) {
  return (
    <input type={type} defaultValue={value} style={{
      background:"var(--bg)", border:"1px solid var(--line)", borderRadius:4,
      padding:"6px 10px", fontSize:12, color:"var(--ink)",
      fontFamily: mono ? "var(--mono)" : "var(--ui)", width
    }}/>
  );
}
function Radio({ options, value }) {
  return (
    <div style={{display:"flex", gap:0, border:"1px solid var(--line)", borderRadius:4, overflow:"hidden", width:"fit-content"}}>
      {options.map(o => (
        <button key={o} style={{
          padding:"6px 14px", fontSize:11, fontFamily:"var(--ui)",
          background: value === o ? "var(--ink-1)" : "var(--bg)",
          color: value === o ? "var(--bg)" : "var(--ink-2)",
          border:"0", borderLeft: o === options[0] ? "0" : "1px solid var(--line)",
          cursor:"pointer", letterSpacing:"0.04em"
        }}>{o}</button>
      ))}
    </div>
  );
}
function NumInp({ value, suffix }) {
  return (
    <div style={{display:"flex", alignItems:"center", gap:6}}>
      <input type="number" defaultValue={value} style={{
        background:"var(--bg)", border:"1px solid var(--line)", borderRadius:4,
        padding:"6px 10px", fontSize:12, color:"var(--ink)",
        fontFamily:"var(--mono)", width:90
      }}/>
      {suffix && <span className="mono dim" style={{fontSize:11}}>{suffix}</span>}
    </div>
  );
}

// ---------- TAB 1: OUTPUTS ----------
function TabOutputs() {
  const [ndi, setNdi] = useState(true);
  const [rtmp, setRtmp] = useState(false);
  const [srt, setSrt] = useState(true);
  const [direct, setDirect] = useState(false);
  const [fk, setFk] = useState(true);
  const [inv, setInv] = useState(false);
  const [vert, setVert] = useState(false);

  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Resolution" count="3">
        <FieldRow label="Video Size" classification="CONFIRM" hint="Master output canvas size">
          <Sel value="1080p" options={["720p","1080p","1440p","4K (UHD)"]}/>
        </FieldRow>
        <FieldRow label="Frame Rate" classification="CONFIRM">
          <div style={{display:"flex", gap:10, alignItems:"center"}}>
            <Sel value="60 fps" options={["24 fps","25 fps","30 fps","50 fps","60 fps","Custom…"]}/>
            <span className="dim" style={{fontSize:11}}>or manual 1–120</span>
          </div>
        </FieldRow>
        <FieldRow label="9:16 Vertical Mode" classification="CONFIRM" hint="Rotate canvas for mobile/social cuts">
          <Sw on={vert} onToggle={()=>setVert(!vert)}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Live Pipeline" count="4">
        <FieldRow label="NDI Output" classification="CONFIRM" hint={ndi ? "Stream Name: EBS_Day2_T071  ·  Group: Public" : "Off"}>
          <Sw on={ndi} onToggle={()=>setNdi(!ndi)}/>
          {ndi && (
            <div style={{display:"flex", gap:8, marginTop:4}}>
              <Inp value="EBS_Day2_T071" width={220}/>
              <Sel value="Public" options={["Public","Private"]}/>
            </div>
          )}
        </FieldRow>
        <FieldRow label="RTMP Stream" classification="CONFIRM" hint={rtmp ? "rtmp://live.cdn.example/app" : "Off"}>
          <Sw on={rtmp} onToggle={()=>setRtmp(!rtmp)}/>
          {rtmp && (
            <div style={{display:"flex", gap:8, marginTop:4}}>
              <Inp value="rtmp://live.cdn.example/app" width={300} mono/>
              <Inp value="••••••••" width={120} mono/>
            </div>
          )}
        </FieldRow>
        <FieldRow label="SRT Output" classification="CONFIRM" hint={srt ? "srt://10.0.4.18:9000  ·  latency 1500ms  ·  AES-128" : "Off"}>
          <Sw on={srt} onToggle={()=>setSrt(!srt)}/>
          {srt && (
            <div style={{display:"flex", gap:8, marginTop:4, flexWrap:"wrap"}}>
              <Inp value="srt://10.0.4.18:9000" width={240} mono/>
              <NumInp value={1500} suffix="ms"/>
              <Sel value="AES-128" options={["None","AES-128","AES-256"]}/>
            </div>
          )}
        </FieldRow>
        <FieldRow label="DIRECT Output" classification="CONFIRM" hint={direct ? "SDI 12G · Decklink Quad 2 · Slot 1" : "Off"}>
          <Sw on={direct} onToggle={()=>setDirect(!direct)}/>
          {direct && (
            <div style={{display:"flex", gap:8, marginTop:4}}>
              <Sel value="Decklink Quad 2 · Slot 1" options={["Decklink Quad 2 · Slot 1","Decklink Quad 2 · Slot 2","Decklink 8K Pro"]}/>
            </div>
          )}
        </FieldRow>
      </SubGroup>

      <SubGroup title="Output Mode" count="3">
        <FieldRow label="Fill & Key Output" classification="CONFIRM" hint="Two-stream alpha for vision-mixers">
          <Sw on={fk} onToggle={()=>setFk(!fk)}/>
        </FieldRow>
        <FieldRow label="Key Type" classification="CONFIRM">
          <Radio options={["Alpha","Luma"]} value="Alpha"/>
        </FieldRow>
        <FieldRow label="Invert Key" classification="CONFIRM">
          <Sw on={inv} onToggle={()=>setInv(!inv)}/>
        </FieldRow>
      </SubGroup>
    </div>
  );
}

// ---------- TAB 2: GFX ----------
function TabGFX() {
  const [showLB, setShowLB] = useState(false);
  const [indent, setIndent] = useState(true);
  const [bounce, setBounce] = useState(false);
  const [hilight, setHilight] = useState(true);
  const [flag, setFlag] = useState(true);
  const [order, setOrder] = useState(false);
  const [photo, setPhoto] = useState(true);
  const [seat, setSeat] = useState(false);
  const [chip, setChip] = useState(true);
  const [strip, setStrip] = useState(false);

  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Layout" count="6">
        <FieldRow label="Board Position" classification="FREE">
          <Sel value="Centre" options={["Left","Centre","Right","Top"]}/>
        </FieldRow>
        <FieldRow label="Player Layout" classification="FREE" hint="Vert-Bot-Fit forces players inside safe area">
          <Sel value="Horizontal" options={["Horizontal","Vert-Bot-Spill","Vert-Bot-Fit","Vert-Top-Spill","Vert-Top-Fit"]}/>
        </FieldRow>
        <FieldRow label="X Margin" classification="FREE"><Slider value={0.04}/></FieldRow>
        <FieldRow label="Top Margin" classification="FREE"><Slider value={0.05}/></FieldRow>
        <FieldRow label="Bot Margin" classification="FREE"><Slider value={0.04}/></FieldRow>
        <FieldRow label="Leaderboard Position" classification="FREE">
          <Sel value="Off" options={["Off","Centre","Left","Right"]}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Card & Player" count="4">
        <FieldRow label="Reveal Players" classification="CONFIRM">
          <Sel value="Immediate" options={["Immediate","On Action","After Bet","On Action + Next"]}/>
        </FieldRow>
        <FieldRow label="How to Show Fold" classification="CONFIRM">
          <div style={{display:"flex", gap:8, alignItems:"center"}}>
            <Sel value="Immediate" options={["Immediate","After Delay","On Next Action","Never"]}/>
            <NumInp value={0.5} suffix="s delay"/>
          </div>
        </FieldRow>
        <FieldRow label="Reveal Cards" classification="CONFIRM">
          <Sel value="Immediate" options={["Immediate","After Action","End of Hand","Never","Showdown Cash","Showdown Tourney"]}/>
        </FieldRow>
        <FieldRow label="Show Leaderboard" classification="FREE" hint={showLB ? "Auto-stats every 1 hand · 10s · start at hand #5" : "Manual only"}>
          <Sw on={showLB} onToggle={()=>setShowLB(!showLB)}/>
          {showLB && (
            <div style={{display:"grid", gridTemplateColumns:"repeat(2,auto)", gap:"8px 16px", marginTop:6, fontSize:11}}>
              <span className="dim">Auto Stats</span><Sw on={true} onToggle={()=>{}}/>
              <span className="dim">Display Time</span><NumInp value={10} suffix="s"/>
              <span className="dim">Start After Hand</span><NumInp value={5}/>
              <span className="dim">Update Every</span><NumInp value={1} suffix="hand(s)"/>
            </div>
          )}
        </FieldRow>
      </SubGroup>

      <SubGroup title="Animation" count="4">
        <FieldRow label="Transition In" classification="FREE">
          <div style={{display:"flex", gap:10, alignItems:"center"}}>
            <Sel value="Default (Fade)" options={["Default (Fade)","Slide","Pop","Expand"]}/>
            <Slider value={0.3} min={0.1} max={2.0} step={0.05} suffix="s"/>
          </div>
        </FieldRow>
        <FieldRow label="Transition Out" classification="FREE">
          <div style={{display:"flex", gap:10, alignItems:"center"}}>
            <Sel value="Default (Fade)" options={["Default (Fade)","Slide","Pop","Expand"]}/>
            <Slider value={0.3} min={0.1} max={2.0} step={0.05} suffix="s"/>
          </div>
        </FieldRow>
        <FieldRow label="Indent Action Player" classification="FREE">
          <Sw on={indent} onToggle={()=>setIndent(!indent)}/>
        </FieldRow>
        <FieldRow label="Bounce Action Player" classification="FREE">
          <Sw on={bounce} onToggle={()=>setBounce(!bounce)}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Player Display Toggles" count="8">
        <FieldRow label="Card Style" classification="CONFIRM">
          <Sel value="Classic" options={["Classic","Modern","Minimal"]}/>
        </FieldRow>
        <FieldRow label="Highlight Active Player" classification="FREE"><Sw on={hilight} onToggle={()=>setHilight(!hilight)}/></FieldRow>
        <FieldRow label="Show Player Flag" classification="FREE"><Sw on={flag} onToggle={()=>setFlag(!flag)}/></FieldRow>
        <FieldRow label="Show Player Order" classification="FREE"><Sw on={order} onToggle={()=>setOrder(!order)}/></FieldRow>
        <FieldRow label="Show Player Photo" classification="FREE"><Sw on={photo} onToggle={()=>setPhoto(!photo)}/></FieldRow>
        <FieldRow label="Show Seat Number" classification="FREE"><Sw on={seat} onToggle={()=>setSeat(!seat)}/></FieldRow>
        <FieldRow label="Show Chip Count" classification="FREE"><Sw on={chip} onToggle={()=>setChip(!chip)}/></FieldRow>
        <FieldRow label="Show Score Strip" classification="FREE"><Sw on={strip} onToggle={()=>setStrip(!strip)}/></FieldRow>
      </SubGroup>

      <SubGroup title="Active Skin (CCR-025)">
        <FieldRow label="Current Active" classification="CONFIRM" hint="Skin Editor opens via Lobby header [Graphic Editor] button">
          <div style={{display:"flex", gap:8, alignItems:"center"}}>
            <Sel value="WSOP_Classic_v3.gfskin" options={["WSOP_Classic_v3.gfskin","WSOP_Bracelet_v2.gfskin","EBS_Default.gfskin"]}/>
            <button className="btn ghost sm">Apply</button>
          </div>
        </FieldRow>
      </SubGroup>
    </div>
  );
}

// ---------- TAB 3: DISPLAY ----------
function TabDisplay() {
  const [hash, setHash] = useState(false);
  const [trail, setTrail] = useState(false);
  const [div, setDiv] = useState(false);
  const [side, setSide] = useState(true);
  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Blinds" count="5">
        <FieldRow label="Show Blinds" classification="FREE">
          <Sel value="When Changed" options={["Always","When Changed","Never"]}/>
        </FieldRow>
        <FieldRow label="Show Hand #" classification="FREE"><Sw on={hash} onToggle={()=>setHash(!hash)}/></FieldRow>
        <FieldRow label="Currency Symbol" classification="FREE" hint="Applies to all monetary fields">
          <Inp value="$" width={80} mono/>
        </FieldRow>
        <FieldRow label="Trailing Currency" classification="FREE" hint={trail ? '"100$" — symbol after' : '"$100" — symbol before'}>
          <Sw on={trail} onToggle={()=>setTrail(!trail)}/>
        </FieldRow>
        <FieldRow label="Divide by 100" classification="FREE" hint="Cents → dollars (for cash games stored in cents)">
          <Sw on={div} onToggle={()=>setDiv(!div)}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Precision" count="5">
        <FieldRow label="Leaderboard" classification="FREE">
          <Sel value="Exact Amount" options={["Exact Amount","Smart k-M","Smart Amount","Divide"]}/>
        </FieldRow>
        <FieldRow label="Player Stack" classification="FREE">
          <Sel value="Smart k-M" options={["Exact Amount","Smart k-M","Smart Amount","Divide"]}/>
        </FieldRow>
        <FieldRow label="Player Action" classification="FREE">
          <Sel value="Smart Amount" options={["Exact Amount","Smart k-M","Smart Amount","Divide"]}/>
        </FieldRow>
        <FieldRow label="Blinds" classification="FREE">
          <Sel value="Smart Amount" options={["Exact Amount","Smart k-M","Smart Amount","Divide"]}/>
        </FieldRow>
        <FieldRow label="Pot" classification="FREE">
          <Sel value="Smart Amount" options={["Exact Amount","Smart k-M","Smart Amount","Divide"]}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Mode" count="4">
        <FieldRow label="Chipcount Mode" classification="FREE" hint="BB mode requires non-zero BB">
          <Radio options={["Amount","BB"]} value="Amount"/>
        </FieldRow>
        <FieldRow label="Pot Mode" classification="FREE">
          <Radio options={["Amount","BB"]} value="Amount"/>
        </FieldRow>
        <FieldRow label="Bets Mode" classification="FREE">
          <Radio options={["Amount","BB"]} value="Amount"/>
        </FieldRow>
        <FieldRow label="Display Side Pot" classification="FREE"><Sw on={side} onToggle={()=>setSide(!side)}/></FieldRow>
      </SubGroup>

      <SubGroup title="UI Theme (User scope)" count="3">
        <FieldRow label="Theme" classification="FREE" hint="Settings & Lobby chrome — overlay unaffected">
          <Radio options={["Auto","Light","Dark"]} value="Dark"/>
        </FieldRow>
        <FieldRow label="Display Mode" classification="FREE">
          <Sel value="Standard" options={["Standard","Compact","Extended"]}/>
        </FieldRow>
        <FieldRow label="Precision Digits" classification="FREE" hint="Decimal places for Equity / Pot %">
          <NumInp value={0} suffix="0–3"/>
        </FieldRow>
      </SubGroup>
    </div>
  );
}

// ---------- TAB 4: RULES ----------
function TabRules() {
  const [bomb, setBomb] = useState(false);
  const [limit, setLimit] = useState(true);
  const [seatN, setSeatN] = useState(true);
  const [elim, setElim] = useState(false);
  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Game Rules" count="4">
        <FieldRow label="Move Button (Bomb Pot)" classification="LOCK" hint="LOCK during live hand. Edit only when IDLE.">
          <Sw on={bomb} onToggle={()=>setBomb(!bomb)}/>
        </FieldRow>
        <FieldRow label="Limit Raises" classification="CONFIRM">
          <Sw on={limit} onToggle={()=>setLimit(!limit)}/>
        </FieldRow>
        <FieldRow label="Straddle Sleeper" classification="CONFIRM">
          <Sel value="UTG Only" options={["UTG Only","Any","With Sleeper"]}/>
        </FieldRow>
        <FieldRow label="Sleeper Final Action" classification="CONFIRM" hint="Active only when Straddle = With Sleeper">
          <Sel value="BB Rule" options={["BB Rule","Normal"]}/>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Player Display" count="5">
        <FieldRow label="Add Seat #" classification="FREE"><Sw on={seatN} onToggle={()=>setSeatN(!seatN)}/></FieldRow>
        <FieldRow label="Show as Eliminated" classification="FREE"><Sw on={elim} onToggle={()=>setElim(!elim)}/></FieldRow>
        <FieldRow label="Clear Previous Action" classification="FREE">
          <Sel value="On Street Change" options={["On Street Change","On Action","Never"]}/>
        </FieldRow>
        <FieldRow label="Order Players" classification="FREE">
          <Sel value="Seat Order" options={["Seat Order","Stack Size","Alphabetical"]}/>
        </FieldRow>
        <FieldRow label="Hilite Winning Hand" classification="FREE">
          <Sel value="Immediately" options={["Immediately","After Delay","Never"]}/>
        </FieldRow>
      </SubGroup>

      <div style={{
        marginTop:24, padding:"12px 14px", background:"oklch(0.92 0.04 85 / 0.5)",
        border:"1px solid var(--warn)", borderRadius:4, fontSize:12, color:"var(--ink-2)",
        lineHeight:1.55, display:"flex", gap:10
      }}>
        <span style={{color:"var(--warn)", fontWeight:600, flex:"0 0 auto"}}>⚠</span>
        <div>
          <b>Blind level / timer editing is out of scope here.</b> Blind structures (SB / BB / Ante / duration / detail-type) belong to <span className="mono">Flight</span> creation under Lobby, not global Settings.
          See <span className="mono dim">UI-01 §Flight</span> and <span className="mono dim">BlindDetailType</span> enum (Blind / Break / DinnerBreak / HalfBlind / HalfBreak).
        </div>
      </div>
    </div>
  );
}

// ---------- TAB 5: STATS ----------
function TabStats() {
  const [trueOuts, setTrueOuts] = useState(false);
  const [rabbit, setRabbit] = useState(true);
  const [splitIgn, setSplitIgn] = useState(false);
  const [koRank, setKoRank] = useState(true);
  const [chipPct, setChipPct] = useState(true);
  const [showElimS, setShowElimS] = useState(false);
  const [cumul, setCumul] = useState(true);
  const [hideLB, setHideLB] = useState(false);
  const [showElimStrip, setShowElimStrip] = useState(false);
  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Equity & Statistics" count="6">
        <FieldRow label="Show Hand Equities" classification="FREE">
          <Sel value="At showdown" options={["Never","Immediately","At showdown or winner All In","At showdown"]}/>
        </FieldRow>
        <FieldRow label="Show Outs" classification="FREE" hint="Heads-up only — disabled with 3+ players">
          <Sel value="Right" options={["Off","Right","Left"]}/>
        </FieldRow>
        <FieldRow label="True Outs" classification="FREE"><Sw on={trueOuts} onToggle={()=>setTrueOuts(!trueOuts)}/></FieldRow>
        <FieldRow label="Outs Position" classification="FREE">
          <Sel value="Stack" options={["Off","Stack","Winnings"]}/>
        </FieldRow>
        <FieldRow label="Allow Rabbit Hunting" classification="FREE"><Sw on={rabbit} onToggle={()=>setRabbit(!rabbit)}/></FieldRow>
        <FieldRow label="Ignore Split Pots" classification="FREE"><Sw on={splitIgn} onToggle={()=>setSplitIgn(!splitIgn)}/></FieldRow>
      </SubGroup>

      <SubGroup title="Leaderboard" count="6">
        <FieldRow label="Show Knockout Rank" classification="FREE"><Sw on={koRank} onToggle={()=>setKoRank(!koRank)}/></FieldRow>
        <FieldRow label="Show Chipcount %" classification="FREE"><Sw on={chipPct} onToggle={()=>setChipPct(!chipPct)}/></FieldRow>
        <FieldRow label="Show Eliminated in Stats" classification="FREE"><Sw on={showElimS} onToggle={()=>setShowElimS(!showElimS)}/></FieldRow>
        <FieldRow label="Show Cumulative Winnings" classification="FREE"><Sw on={cumul} onToggle={()=>setCumul(!cumul)}/></FieldRow>
        <FieldRow label="Hide LB When Hand Starts" classification="FREE"><Sw on={hideLB} onToggle={()=>setHideLB(!hideLB)}/></FieldRow>
        <FieldRow label="Max BB Multiple in LB" classification="FREE"><NumInp value={150} suffix="× BB"/></FieldRow>
      </SubGroup>

      <SubGroup title="Score Strip" count="3">
        <FieldRow label="Score Strip" classification="FREE">
          <Sel value="Heads Up or All In Showdown" options={["Never","Heads Up or All In Showdown","All In Showdown"]}/>
        </FieldRow>
        <FieldRow label="Show Eliminated in Strip" classification="FREE"><Sw on={showElimStrip} onToggle={()=>setShowElimStrip(!showElimStrip)}/></FieldRow>
        <FieldRow label="Order Strip By" classification="FREE">
          <Sel value="Chip Count" options={["Seating","Chip Count"]}/>
        </FieldRow>
      </SubGroup>
    </div>
  );
}

// ---------- TAB 6: PREFERENCES ----------
function TabPreferences() {
  return (
    <div style={{maxWidth:880}}>
      <SubGroup title="Table" count="3">
        <FieldRow label="Table Name" classification="FREE" hint="Update applies immediately to overlay scoreboard">
          <div style={{display:"flex", gap:8}}>
            <Inp value="Day2 — Featured #071"/>
            <button className="btn ghost sm">Update</button>
          </div>
        </FieldRow>
        <FieldRow label="Table Password" classification="FREE">
          <div style={{display:"flex", gap:8}}>
            <Inp value="••••••••" type="password"/>
            <button className="btn ghost sm">Update</button>
          </div>
        </FieldRow>
        <FieldRow label="Authentication" classification="FREE" hint="PASS resets challenge token. Reset wipes all table local state.">
          <div style={{display:"flex", gap:8}}>
            <button className="btn ghost sm">PASS</button>
            <button className="btn ghost sm" style={{borderColor:"var(--danger)", color:"var(--danger)"}}>Reset</button>
          </div>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Diagnostics" count="3">
        <FieldRow label="PC Specs" hint="Auto-detected · read-only">
          <div className="mono" style={{fontSize:11, color:"var(--ink-3)", lineHeight:1.7}}>
            CPU&nbsp;&nbsp;Intel Xeon W-2295 · 18C / 36T · 3.0 GHz<br/>
            GPU&nbsp;&nbsp;NVIDIA RTX A5000 · 24 GB · driver 552.22<br/>
            RAM&nbsp;&nbsp;128 GB DDR4 ECC<br/>
            OS &nbsp;&nbsp;Windows 11 Pro 24H2 · build 26100.2894
          </div>
        </FieldRow>
        <FieldRow label="Table Diagnostics" hint="RFID, deck, camera, station health">
          <button className="btn ghost sm" style={{width:"fit-content"}}>Open diagnostics</button>
        </FieldRow>
        <FieldRow label="System Log" hint="Live tail of CC engine output">
          <button className="btn ghost sm" style={{width:"fit-content"}}>Open log</button>
        </FieldRow>
      </SubGroup>

      <SubGroup title="Export" count="3">
        <FieldRow label="Hand History Folder" classification="FREE">
          <div style={{display:"flex", gap:8}}>
            <Inp value="C:\\EBS\\Exports\\HandHistory\\" width={320} mono/>
            <button className="btn ghost sm">Pick…</button>
          </div>
        </FieldRow>
        <FieldRow label="Export Logs Folder" classification="FREE">
          <div style={{display:"flex", gap:8}}>
            <Inp value="C:\\EBS\\Logs\\" width={320} mono/>
            <button className="btn ghost sm">Pick…</button>
          </div>
        </FieldRow>
        <FieldRow label="API DB Export Folder" classification="FREE">
          <div style={{display:"flex", gap:8}}>
            <Inp value="C:\\EBS\\Exports\\db\\" width={320} mono/>
            <button className="btn ghost sm">Pick…</button>
          </div>
        </FieldRow>
      </SubGroup>
    </div>
  );
}

// ---------- ROOT ----------
function SettingsScreen() {
  const [tab, setTab] = useState("Outputs");
  const [dirty, setDirty] = useState(false);
  const tabs = [
    { k:"Outputs",     n:13 },
    { k:"GFX",         n:14 },
    { k:"Display",     n:17 },
    { k:"Rules",       n:11 },
    { k:"Stats",       n:15 },
    { k:"Preferences", n: 9 },
  ];
  const Pane = { Outputs: TabOutputs, GFX: TabGFX, Display: TabDisplay, Rules: TabRules, Stats: TabStats, Preferences: TabPreferences }[tab];

  return (
    <div style={{display:"flex", flexDirection:"column", height:"100%"}}>
      {/* Tab bar + scope/role indicator */}
      <div style={{
        display:"flex", alignItems:"center", padding:"0 24px",
        borderBottom:"1px solid var(--line)", background:"var(--bg-alt)",
        gap:0, height:46, flex:"0 0 auto"
      }}>
        <div style={{display:"flex", gap:0, marginRight:"auto"}}>
          {tabs.map(t => (
            <button key={t.k} onClick={()=>setTab(t.k)} style={{
              padding:"0 18px", height:46, border:"0",
              borderBottom: tab === t.k ? "2px solid var(--ink-1)" : "2px solid transparent",
              background:"transparent", cursor:"pointer", fontFamily:"var(--ui)",
              fontSize:13, fontWeight: tab === t.k ? 600 : 500,
              color: tab === t.k ? "var(--ink)" : "var(--ink-3)",
              display:"flex", alignItems:"center", gap:8,
              letterSpacing:"0.02em"
            }}>
              {t.k}
              <span className="mono" style={{fontSize:10, color:"var(--ink-4)"}}>{t.n}</span>
            </button>
          ))}
        </div>
        <span className="mono dim" style={{fontSize:10, letterSpacing:"0.12em", marginRight:14}}>
          ADMIN · GLOBAL SCOPE
        </span>
        <span style={{fontSize:11, color:"var(--ink-3)", display:"flex", alignItems:"center", gap:6}}>
          <span className="dot-sm d-g"/> BO connected · 142ms
        </span>
      </div>

      {/* Status banner */}
      <div style={{
        padding:"8px 24px", borderBottom:"1px solid var(--line-soft)",
        background:"var(--bg)", fontSize:11, display:"flex", gap:24, color:"var(--ink-3)"
      }}>
        <span><b className="mono" style={{color:"var(--live)"}}>FREE</b> applies immediately</span>
        <span><b className="mono" style={{color:"var(--warn)"}}>CONFIRM</b> applies on next HandStarted</span>
        <span><b className="mono" style={{color:"var(--ink-4)"}}>LOCK</b> disabled during live hand</span>
        <span style={{marginLeft:"auto"}} className="dim">2 changes pending · queued for next hand</span>
      </div>

      {/* Content */}
      <div style={{flex:1, overflow:"auto", padding:"24px"}}>
        <div onChange={()=>setDirty(true)} onClick={()=>setDirty(true)}>
          <Pane/>
        </div>
      </div>

      {/* Footer */}
      <div style={{
        flex:"0 0 auto", height:60, borderTop:"1px solid var(--line)",
        background:"var(--bg-alt)", display:"flex", alignItems:"center",
        padding:"0 24px", gap:12
      }}>
        <button className="btn ghost sm" style={{borderColor:"var(--danger)", color:"var(--danger)"}}>
          Reset to default
        </button>
        <span className="dim" style={{fontSize:11, marginLeft:"auto"}}>
          {dirty ? "Unsaved changes in this tab" : "All changes saved · 14:30:18"}
        </span>
        <button className="btn ghost sm">Cancel</button>
        <button className="btn primary sm" style={{
          background: dirty ? "var(--ink-1)" : "var(--line-strong)",
          color: dirty ? "var(--bg)" : "var(--ink-4)",
          border:"0", padding:"7px 18px", fontWeight:600,
          cursor: dirty ? "pointer" : "default"
        }}>
          Save
        </button>
      </div>
    </div>
  );
}

window.EBS_EXTRA = { HandHistoryScreen, AlertsScreen, SettingsScreen };
