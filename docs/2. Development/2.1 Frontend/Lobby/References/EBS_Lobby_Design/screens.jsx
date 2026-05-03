/* global React, window */
const { useState, useMemo } = React;
const { Icon, I } = window.EBS_UI;

const STATUS_LABEL = {
  running: "Running", announced: "Announced", registering: "Registering",
  completed: "Completed", created: "Created",
};

function Badge({ status }) {
  return (
    <span className={"badge b-" + status}>
      <span className="d" />{STATUS_LABEL[status] || status}
    </span>
  );
}

/* ============== SERIES SCREEN ============== */
function SeriesScreen({ data, onOpen }) {
  const [q, setQ] = useState("");
  const [hideOld, setHideOld] = useState(false);
  const grouped = useMemo(() => {
    const filtered = data.filter(s => {
      if (hideOld && s.status === "completed") return false;
      if (q && !(s.name + s.location).toLowerCase().includes(q.toLowerCase())) return false;
      return true;
    });
    const g = {};
    filtered.forEach(s => { (g[s.year] = g[s.year] || []).push(s); });
    return Object.entries(g).sort((a,b) => Number(b[0]) - Number(a[0]));
  }, [data, q, hideOld]);

  return (
    <>
      <div className="toolbar">
        <div className="left">
          <div className="field">
            <span className="ic"><Icon d={I.search} /></span>
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search series, venue, year…" />
          </div>
          <label className="checkbox">
            <input type="checkbox" checked={hideOld} onChange={e => setHideOld(e.target.checked)} />
            Hide completed
          </label>
          <button className="btn ghost sm"><Icon d={I.star} size={12} /> Bookmarks</button>
          <button className="btn ghost sm"><Icon d={I.filter} size={12} /> Filters</button>
        </div>
        <div className="right">
          <span className="legend">
            <span className="lg"><span className="dot-sm d-g" /> Running</span>
            <span className="lg"><span className="dot-sm d-y" /> Registering</span>
            <span className="lg"><span className="dot-sm" style={{background:"var(--info)"}} /> Announced</span>
            <span className="lg"><span className="dot-sm d-x" /> Completed</span>
          </span>
          <button className="btn primary sm"><Icon d={I.plus} size={12} /> New Series</button>
        </div>
      </div>

      <div className="cards-pad">
        {grouped.map(([year, arr]) => (
          <div key={year}>
            <div className="year-band">
              <span>{year}</span>
              <span className="cnt">{arr.length} series</span>
            </div>
            <div className="cardgrid">
              {arr.map(s => (
                <div key={s.id} className="scard" onClick={() => onOpen && onOpen(s)}>
                  <div className="scard-banner" style={{ background: s.accent }}>
                    {s.starred && <span className="star"><Icon d={I.star} size={14} fill="currentColor" sw={0} /></span>}
                    <div className="loc">{s.location}</div>
                    <div className="yr">{s.range}</div>
                  </div>
                  <div className="scard-body">
                    <div className="scard-name">{s.name}</div>
                    <div className="scard-meta">{s.venue}</div>
                    <div className="scard-foot">
                      <span className="scard-evts"><b>{s.events}</b> events</span>
                      <Badge status={s.status} />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

/* ============== EVENTS SCREEN ============== */
function EventsScreen({ data, onOpen }) {
  const [tab, setTab] = useState("running");
  const counts = useMemo(() => {
    const c = { created:0, announced:0, registering:0, running:0, completed:0 };
    data.forEach(e => { c[e.status] = (c[e.status]||0) + 1; });
    return c;
  }, [data]);
  const filtered = data.filter(e => e.status === tab);

  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Total Events</div><div className="k-v">95</div><div className="k-sub">Mar 31 – May 02</div></div>
        <div className="kpi"><div className="k-l">Live Now</div><div className="k-v green">3</div><div className="k-sub">2 featured</div></div>
        <div className="kpi"><div className="k-l">Total Entries</div><div className="k-v">14,287</div><div className="k-sub">+894 today</div></div>
        <div className="kpi"><div className="k-l">Prize Pool</div><div className="k-v">€19.4M</div><div className="k-sub">€1.8M guaranteed</div></div>
        <div className="kpi"><div className="k-l">Active CC</div><div className="k-v amber">3 / 12</div><div className="k-sub">9 idle stations</div></div>
      </div>

      <div className="tabs">
        {["created","announced","registering","running","completed"].map(t => (
          <div key={t} className={"tab" + (tab===t ? " active":"")} onClick={() => setTab(t)}>
            <span style={{textTransform:"capitalize"}}>{t}</span>
            <span className="cnt">{counts[t]}</span>
          </div>
        ))}
      </div>

      <div className="toolbar">
        <div className="left">
          <div className="field"><span className="ic"><Icon d={I.search}/></span><input placeholder="Search by event name, #, buyin…" /></div>
          <button className="btn ghost sm"><Icon d={I.filter} size={12}/> Game · All</button>
          <button className="btn ghost sm">Mode · All</button>
        </div>
        <div className="right">
          <button className="btn ghost sm">Export</button>
          <button className="btn primary sm"><Icon d={I.plus} size={12}/> New Event</button>
        </div>
      </div>

      <div style={{overflow:"auto"}}>
        <table className="dtable">
          <thead>
            <tr>
              <th style={{width:36}} className="ctr">★</th>
              <th style={{width:50}}>No.</th>
              <th style={{width:120}}>Start</th>
              <th>Event</th>
              <th style={{width:80}} className="num">Buy-In</th>
              <th style={{width:60}} className="ctr">Game</th>
              <th style={{width:90}} className="ebs-col ctr">Game Mode</th>
              <th style={{width:80}} className="num">Entries</th>
              <th style={{width:80}} className="num">Re-Ent.</th>
              <th style={{width:70}} className="num">Unique</th>
              <th style={{width:110}}>Status</th>
              <th style={{width:80}} className="ctr">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(e => (
              <tr key={e.no} className={(e.featured ? "feat ":"") + (e.status==="running" ? "live-row":"")} onClick={() => onOpen && onOpen(e)}>
                <td className="ctr">{e.featured ? <Icon d={I.star} size={12} fill="currentColor" sw={0} /> : <span className="muted">—</span>}</td>
                <td className="mono"><b>#{e.no}</b></td>
                <td className="mono">{e.time}</td>
                <td><b>{e.name}</b></td>
                <td className="num mono"><b>{e.buyin}</b></td>
                <td className="ctr mono">{e.game}</td>
                <td className="ebs-col ctr">{e.mode}</td>
                <td className="num mono">{e.entries != null ? <b>{e.entries.toLocaleString()}</b> : <span className="muted">—</span>}</td>
                <td className="num mono">{e.reentries != null ? e.reentries.toLocaleString() : <span className="muted">—</span>}</td>
                <td className="num mono">{e.unique != null ? e.unique.toLocaleString() : <span className="muted">—</span>}</td>
                <td><Badge status={e.status}/></td>
                <td className="ctr">
                  <button className="btn xs ghost">Open ›</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

/* ============== FLIGHTS SCREEN ============== */
function FlightsScreen({ data, onOpen }) {
  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Event</div><div className="k-v" style={{fontSize:14, lineHeight:1.4, fontFamily:"var(--ui)"}}>#5 Europe Main Event</div><div className="k-sub">€5,300 · NLH</div></div>
        <div className="kpi"><div className="k-l">Total Entries</div><div className="k-v">2,645</div><div className="k-sub">1,273 unique</div></div>
        <div className="kpi"><div className="k-l">Surviving</div><div className="k-v green">918</div><div className="k-sub">35% of field</div></div>
        <div className="kpi"><div className="k-l">Prize Pool</div><div className="k-v">€13.225M</div><div className="k-sub">€2.4M to 1st</div></div>
        <div className="kpi"><div className="k-l">In The Money</div><div className="k-v amber">198</div><div className="k-sub">Day3 bubble</div></div>
      </div>

      <div className="toolbar">
        <div className="left">
          <span className="dim" style={{fontSize:11, letterSpacing:"0.10em", textTransform:"uppercase"}}>8 Flights · Day1A → Final</span>
        </div>
        <div className="right">
          <button className="btn ghost sm">Schedule</button>
          <button className="btn primary sm"><Icon d={I.plus} size={12}/> New Flight</button>
        </div>
      </div>

      <div style={{overflow:"auto"}}>
        <table className="dtable">
          <thead>
            <tr>
              <th style={{width:160}}>Start Time</th>
              <th style={{width:60}}>#</th>
              <th>Flight</th>
              <th style={{width:140}} className="num">Entries</th>
              <th style={{width:120}} className="num">Survivors</th>
              <th style={{width:100}} className="num">Tables</th>
              <th style={{width:140}}>Status</th>
              <th style={{width:90}} className="ctr">Action</th>
            </tr>
          </thead>
          <tbody>
            {data.map(f => (
              <tr key={f.name} className={f.active ? "feat live-row" : ""} onClick={() => f.active && onOpen && onOpen(f)}>
                <td className="mono">{f.time}</td>
                <td className="mono">#{f.no}</td>
                <td><b>{f.name}</b>{f.active && <span className="muted" style={{marginLeft:8, fontSize:11}}>· in progress</span>}</td>
                <td className="num mono">{f.entries}</td>
                <td className="num mono"><b style={{color: f.active ? "var(--feat-ink)" : undefined}}>{f.players.toLocaleString()}</b></td>
                <td className="num mono">{f.tables}</td>
                <td><Badge status={f.status}/></td>
                <td className="ctr">{f.active ? <button className="btn xs primary">Open ›</button> : <span className="muted">—</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

/* ============== TABLES SCREEN ============== */
function TablesScreen({ tables, waitlist, onLaunch }) {
  const [q, setQ] = useState("");
  const [view, setView] = useState("grid");
  const filtered = tables.filter(t => !q || t.id.toLowerCase().includes(q.toLowerCase()));

  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Players</div><div className="k-v">918<span className="dim" style={{fontSize:13, fontFamily:"var(--mono)"}}>/919</span></div><div className="k-sub">17 elim · last 1h</div></div>
        <div className="kpi"><div className="k-l">Total Tables</div><div className="k-v">124</div><div className="k-sub">1,116 seats</div></div>
        <div className="kpi"><div className="k-l">Waiting</div><div className="k-v red">12</div><div className="k-sub">avg 3m</div></div>
        <div className="kpi"><div className="k-l">Active CC</div><div className="k-v green">3 <span className="dim" style={{fontSize:13, fontFamily:"var(--mono)"}}>/ 12</span></div><div className="k-sub">2 marquee · 1 alert</div></div>
        <div className="kpi"><div className="k-l">Avg Stack</div><div className="k-v">164,553</div><div className="k-sub">27.4 BB</div></div>
      </div>

      <div className="levels">
        <span className="lvl-label">Levels</span>
        <div className="lvl now">
          <span className="role">Now · L17</span>
          <span className="blinds">6,000 / 12,000</span>
          <span className="meta">ante 12,000 · 60min</span>
        </div>
        <div className="lvl next">
          <span className="role">Next · L18</span>
          <span className="blinds">8,000 / 16,000</span>
          <span className="meta">ante 16,000 · 60min</span>
        </div>
        <div className="lvl">
          <span className="role">L19</span>
          <span className="blinds">10,000 / 20,000</span>
          <span className="meta">ante 20,000 · 60min</span>
        </div>
        <div className="lvl-clock"><span className="l">L18 In</span>22:48</div>
      </div>

      <div className="toolbar">
        <div className="left">
          <div className="field"><span className="ic"><Icon d={I.search}/></span><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Find table or player…" /></div>
          <div className="seg">
            <button className={view==="grid"?"on":""} onClick={()=>setView("grid")}>Grid</button>
            <button className={view==="map"?"on":""} onClick={()=>setView("map")}>Floor Map</button>
            <button className={view==="cc"?"on":""} onClick={()=>setView("cc")}>CC Focus</button>
          </div>
          <span className="checkbox"><span className="dim mono" style={{fontSize:11}}>Auto Seating</span> <b style={{fontSize:11}}>Enabled</b></span>
        </div>
        <div className="right">
          <span className="legend">
            <span className="lg"><span className="seat s-a" style={{width:12,height:12,fontSize:0,margin:0}} /> Active</span>
            <span className="lg"><span className="seat s-e" style={{width:12,height:12,fontSize:0,margin:0}} /> Empty</span>
            <span className="lg"><span className="seat s-r" style={{width:12,height:12,fontSize:0,margin:0}} /> Elim</span>
          </span>
          <button className="btn primary sm"><Icon d={I.plus} size={12}/> Break Table</button>
        </div>
      </div>

      <div className="tables-grid">
        <div className="tables-table-wrap">
          <table className="dtable">
            <thead>
              <tr>
                <th style={{width:130}}>Table</th>
                {[1,2,3,4,5,6,7,8,9].map(n => <th key={n} className="ctr" style={{width:30}}>{n}</th>)}
                <th className="ctr" style={{width:46}}>Std</th>
                <th className="ebs-col ctr" style={{width:60}}>RFID</th>
                <th className="ebs-col ctr" style={{width:64}}>Deck</th>
                <th className="ebs-col ctr" style={{width:50}}>Out</th>
                <th className="ebs-col" style={{width:200}}>Command Center</th>
                <th className="ebs-col ctr" style={{width:90}}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(t => (
                <tr key={t.id} className={(t.featured?"feat ":"") + (t.cc==="live"?"live-row":"")}>
                  <td>
                    {t.featured && <span className="star" style={{marginRight:4}}>★</span>}
                    <b>{t.id}</b>
                    {t.marquee && <span className="badge b-running" style={{marginLeft:6, fontSize:9, padding:"1px 5px"}}><span className="d"/>FT</span>}
                  </td>
                  {t.seats.map((s, i) => (
                    <td key={i} className="ctr"><span className={"seat s-" + s}>{s==="e"?"":i+1}</span></td>
                  ))}
                  <td className="ctr mono"><b>{t.seats.filter(s=>s==="a").length}</b></td>
                  <td className="ebs-col ctr mono">{t.rfid==="rdy" && <><span className="dot-sm d-g"/>Rdy</>}{t.rfid==="err" && <><span className="dot-sm d-r"/>Err</>}{t.rfid==="off" && <span className="muted">—</span>}</td>
                  <td className="ebs-col ctr mono">{t.deck ? <><span className={"dot-sm " + (t.deck.startsWith("0")?"d-y":"d-g")}/>{t.deck}</> : <span className="muted">—</span>}</td>
                  <td className="ebs-col ctr mono">{t.out ? <>{t.out}<span className="dot-sm d-g" style={{marginLeft:4, marginRight:0}}/></> : <span className="muted">—</span>}</td>
                  <td className="ebs-col">
                    <span className={"cc-cell " + t.cc}>
                      <span className="cdot"/>
                      {t.cc==="live" && "LIVE"}
                      {t.cc==="idle" && "IDLE"}
                      {t.cc==="err"  && "ERROR"}
                      {t.op && <span className="op">· {t.op}</span>}
                    </span>
                  </td>
                  <td className="ebs-col ctr">
                    {t.cc === "idle"
                      ? <button className="btn xs primary" onClick={(e)=>{e.stopPropagation(); onLaunch && onLaunch(t);}}>Launch ⚡</button>
                      : t.cc === "err"
                        ? <button className="btn xs" style={{borderColor:"var(--danger)", color:"var(--danger-ink)"}}>Open ⚠</button>
                        : <button className="btn xs ghost">Open ›</button>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <aside className="waitlist">
          <div className="wl-head"><span>Waiting List</span><b>{waitlist.length}</b></div>
          <div className="wl-list">
            {waitlist.map((n, i) => (
              <div key={i} className="wl-row">
                <span className="num">{String(i+1).padStart(2,"0")}</span>
                <span className="nm">{n}</span>
                <span className="act">drag →</span>
              </div>
            ))}
          </div>
          <div className="assign-hint">Drag a name onto a seat to assign.</div>
        </aside>
      </div>
    </>
  );
}

/* ============== PLAYERS SCREEN ============== */
function PlayersScreen({ data }) {
  const [q, setQ] = useState("");
  const [stateFilter, setStateFilter] = useState("all");
  const filtered = data.filter(p => {
    if (stateFilter !== "all" && p.state !== stateFilter) return false;
    if (q && !p.name.toLowerCase().includes(q.toLowerCase())) return false;
    return true;
  });
  const max = Math.max(...data.map(p => p.chips));

  return (
    <>
      <div className="kpi-strip">
        <div className="kpi"><div className="k-l">Players</div><div className="k-v">918</div><div className="k-sub">15 in view</div></div>
        <div className="kpi"><div className="k-l">Total Stack</div><div className="k-v">151.06M</div><div className="k-sub">recorded</div></div>
        <div className="kpi"><div className="k-l">Entered Stacks</div><div className="k-v">153.11M</div><div className="k-sub">starting</div></div>
        <div className="kpi"><div className="k-l">Difference</div><div className="k-v red">−2.05M</div><div className="k-sub">−1.34%</div></div>
        <div className="kpi"><div className="k-l">Avg Stack</div><div className="k-v">164,553</div><div className="k-sub">13.7 BB</div></div>
      </div>

      <div className="toolbar">
        <div className="left">
          <div className="field"><span className="ic"><Icon d={I.search}/></span><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search player, country…" /></div>
          <div className="seg">
            {["all","active","away","elim"].map(s => (
              <button key={s} className={stateFilter===s?"on":""} onClick={()=>setStateFilter(s)}>{s==="all"?"All":s.charAt(0).toUpperCase()+s.slice(1)}</button>
            ))}
          </div>
          <button className="btn ghost sm"><Icon d={I.star} size={12}/> Featured</button>
        </div>
        <div className="right">
          <button className="btn ghost sm">Export CSV</button>
          <button className="btn ghost sm">Print Chip Counts</button>
        </div>
      </div>

      <div style={{overflow:"auto"}}>
        <table className="dtable">
          <thead>
            <tr>
              <th style={{width:50}} className="num">#</th>
              <th>Player</th>
              <th style={{width:60}} className="ctr">Country</th>
              <th style={{width:200}} className="num">Chips</th>
              <th style={{width:70}} className="num">BB</th>
              <th style={{width:80}}>State</th>
              <th style={{width:60}} className="ebs-col num">VPIP</th>
              <th style={{width:55}} className="ebs-col num">PFR</th>
              <th style={{width:55}} className="ebs-col num">AGR</th>
              <th style={{width:50}} className="ctr">FT</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(p => (
              <tr key={p.place} className={p.featured ? "feat" : ""}>
                <td className="num mono"><b>{p.place}</b></td>
                <td>
                  <span className="flag-chip">
                    <span className="fl">{p.flag}</span>
                    <b>{p.name}</b>
                    {p.featured && <span className="star" style={{marginLeft:2}}>★</span>}
                  </span>
                </td>
                <td className="ctr mono dim">{p.country}</td>
                <td className="num mono">
                  <span className="chipsbar"><span style={{width: (p.chips/max*100).toFixed(0)+"%"}}/></span>
                  <b>{p.chips.toLocaleString()}</b>
                </td>
                <td className="num mono">{p.bb.toFixed(1)}</td>
                <td><span className={"state-pill st-"+p.state}>{p.state}</span></td>
                <td className="num mono ebs-col">{p.vpip}%</td>
                <td className="num mono ebs-col">{p.pfr}%</td>
                <td className="num mono ebs-col">{p.agr.toFixed(1)}</td>
                <td className="ctr">{p.ft ? <span className="star">★</span> : <span className="muted">—</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

/* ============== LOGIN SCREEN ============== */
function LoginScreen({ onLogin }) {
  return (
    <div className="login-page">
      <div className="login-card">
        <div className="lk"><div className="brand-mark">E</div><span className="name">EBS LOBBY</span></div>
        <h2>Welcome back</h2>
        <div className="sub">Sign in to the broadcasting console.</div>
        <div className="input-group"><label>Email</label><input defaultValue="j.kim@ebs.live" /></div>
        <div className="input-group"><label>Password</label><input type="password" defaultValue="••••••••" /></div>
        <div className="row">
          <label className="checkbox"><input type="checkbox" defaultChecked /> <span>Keep me signed in</span></label>
          <a href="#">Forgot password?</a>
        </div>
        <button className="btn primary btn-block" onClick={onLogin}>Sign In</button>
        <div className="or">or</div>
        <button className="btn ghost btn-block">Continue with Entra ID</button>
        <div className="sub" style={{marginTop:18, marginBottom:0, fontSize:10.5, textAlign:"center", letterSpacing:"0.06em"}}>EBS v5.0.0 · WSOP LIVE Integrated Broadcast System</div>
      </div>
    </div>
  );
}

window.EBS_SCREENS = { SeriesScreen, EventsScreen, FlightsScreen, TablesScreen, PlayersScreen, LoginScreen };
