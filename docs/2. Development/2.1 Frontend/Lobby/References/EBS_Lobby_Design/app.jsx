/* global React, ReactDOM, window */
const { useState, useEffect } = React;
const { TopBar, Rail, Breadcrumb } = window.EBS_UI;
const { SeriesScreen, EventsScreen, FlightsScreen, TablesScreen, PlayersScreen, LoginScreen } = window.EBS_SCREENS;
const { HandHistoryScreen, AlertsScreen, SettingsScreen } = window.EBS_EXTRA;
const { SERIES, EVENTS, FLIGHTS, TABLES, WAITLIST, PLAYERS } = window.EBS_DATA;
const { TweaksPanel, useTweaks, TweakSection, TweakRadio, TweakToggle, TweakSelect } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "density": "default",
  "showEbsCols": true,
  "startScreen": "tables",
  "showLogin": false
}/*EDITMODE-END*/;

function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [loggedIn, setLoggedIn] = useState(!tweaks.showLogin);
  const [screen, setScreen] = useState(tweaks.startScreen || "tables");
  const [railCollapsed, setRailCollapsed] = useState(false);
  const [clock, setClock] = useState(() => new Date().toLocaleTimeString("en-GB", { hour:"2-digit", minute:"2-digit", second:"2-digit"}));
  const [launchModal, setLaunchModal] = useState(null);

  useEffect(() => {
    const t = setInterval(() => {
      setClock(new Date().toLocaleTimeString("en-GB", { hour:"2-digit", minute:"2-digit", second:"2-digit"}));
    }, 1000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", tweaks.theme);
    document.documentElement.setAttribute("data-density", tweaks.density);
    document.documentElement.setAttribute("data-ebs-cols", tweaks.showEbsCols ? "on" : "off");
  }, [tweaks.theme, tweaks.density, tweaks.showEbsCols]);

  if (tweaks.showLogin && !loggedIn) {
    return <LoginScreen onLogin={() => setLoggedIn(true)} />;
  }

  const trails = {
    series:  [{ label: "Home", go: "series" }],
    events:  [{ label: "Home", go: "series" }, { label: "WPS · EU 2026", go: "events" }, { label: "Events" }],
    flights: [{ label: "Home", go: "series" }, { label: "WPS · EU 2026", go: "events" }, { label: "Event #5 · Europe Main", go: "flights" }, { label: "Flights" }],
    tables:  [{ label: "Home", go: "series" }, { label: "WPS · EU 2026", go: "events" }, { label: "Event #5", go: "flights" }, { label: "Day2", go: "tables" }, { label: "Tables" }],
    players: [{ label: "Home", go: "series" }, { label: "WPS · EU 2026", go: "events" }, { label: "Event #5", go: "flights" }, { label: "Day2", go: "tables" }, { label: "Players" }],
    hands:    [{ label: "Home", go: "series" }, { label: "WPS · EU 2026", go: "events" }, { label: "Event #5", go: "flights" }, { label: "Day2", go: "tables" }, { label: "Hand History · Day2-#071" }],
    alerts:   [{ label: "Home", go: "series" }, { label: "Alerts" }],
    settings: [{ label: "Home", go: "series" }, { label: "Settings" }],
  };

  let body = null;
  if (screen === "series")  body = <SeriesScreen  data={SERIES}    onOpen={() => setScreen("events")} />;
  if (screen === "events")  body = <EventsScreen  data={EVENTS}    onOpen={() => setScreen("flights")} />;
  if (screen === "flights") body = <FlightsScreen data={FLIGHTS}   onOpen={() => setScreen("tables")} />;
  if (screen === "tables")  body = <TablesScreen  tables={TABLES}  waitlist={WAITLIST} onLaunch={t => setLaunchModal(t)} />;
  if (screen === "players") body = <PlayersScreen data={PLAYERS} />;
  if (screen === "hands")    body = <HandHistoryScreen />;
  if (screen === "alerts")   body = <AlertsScreen />;
  if (screen === "settings") body = <SettingsScreen />;

  return (
    <div className="app" data-rail={railCollapsed ? "collapsed" : "expanded"}>
      <TopBar clock={clock} onToggleRail={() => setRailCollapsed(c => !c)} />
      <Rail screen={screen} setScreen={setScreen} collapsed={railCollapsed} />
      <main className="main">
        <Breadcrumb trail={trails[screen]} setScreen={setScreen} />
        {body}
      </main>

      {launchModal && (
        <div className="sheet-bg" onClick={() => setLaunchModal(null)}>
          <div className="sheet" onClick={e => e.stopPropagation()}>
            <h3>Launch Command Center · {launchModal.id}</h3>
            <div className="body">
              <p style={{marginBottom:10}}>This will allocate an idle CC operator to <b>{launchModal.id}</b> and bring the table on-air.</p>
              <div className="kpi-strip" style={{border:"1px solid var(--line)", borderRadius:6}}>
                <div className="kpi" style={{borderRight:"1px solid var(--line-soft)"}}><div className="k-l">Seats</div><div className="k-v" style={{fontSize:14}}>{launchModal.seats.filter(s=>s==="a").length} / 9</div></div>
                <div className="kpi" style={{borderRight:"1px solid var(--line-soft)"}}><div className="k-l">RFID</div><div className="k-v" style={{fontSize:14}}>Pairing…</div></div>
                <div className="kpi"><div className="k-l">Operator</div><div className="k-v" style={{fontSize:14}}>Auto-assign</div></div>
              </div>
            </div>
            <div className="foot">
              <button className="btn ghost sm" onClick={() => setLaunchModal(null)}>Cancel</button>
              <button className="btn live sm" onClick={() => setLaunchModal(null)}>● Launch</button>
            </div>
          </div>
        </div>
      )}

      <TweaksPanel title="Tweaks">
        <TweakSection label="Appearance">
          <TweakRadio label="Theme" value={tweaks.theme} options={[{value:"light",label:"Light"},{value:"dark",label:"Dark"}]} onChange={v => setTweak("theme", v)} />
          <TweakRadio label="Density" value={tweaks.density} options={[{value:"compact",label:"Compact"},{value:"default",label:"Default"},{value:"cozy",label:"Cozy"}]} onChange={v => setTweak("density", v)} />
        </TweakSection>
        <TweakSection label="Layout">
          <TweakToggle label="Show EBS-only columns" value={tweaks.showEbsCols} onChange={v => setTweak("showEbsCols", v)} />
          <TweakToggle label="Show login screen first" value={tweaks.showLogin} onChange={v => { setTweak("showLogin", v); setLoggedIn(!v); }} />
        </TweakSection>
        <TweakSection label="Navigation">
          <TweakSelect label="Jump to screen" value={screen} options={[
            {value:"series",label:"Series"},{value:"events",label:"Events"},{value:"flights",label:"Flights"},
            {value:"tables",label:"Tables"},{value:"players",label:"Players"},
            {value:"hands",label:"Hand History"},{value:"alerts",label:"Alerts"},{value:"settings",label:"Settings"}
          ]} onChange={v => setScreen(v)} />
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
