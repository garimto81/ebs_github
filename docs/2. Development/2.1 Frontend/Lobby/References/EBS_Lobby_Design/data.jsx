/* global window */
// EBS Lobby — sample data

const SERIES = [
  {
    id: "wps26",
    year: 2026,
    name: "World Poker Series 2026",
    location: "Las Vegas, NV",
    venue: "Horseshoe & Paris",
    range: "May 27 – Jul 16",
    events: 95,
    status: "running",
    accent: "oklch(0.45 0.08 145)",
    starred: true,
  },
  {
    id: "wpse26",
    year: 2026,
    name: "World Poker Series Europe",
    location: "Cannes, FR",
    venue: "Palais des Festivals",
    range: "Sep 15 – Oct 5",
    events: 14,
    status: "announced",
    accent: "oklch(0.42 0.08 250)",
  },
  {
    id: "circ-syd",
    year: 2026,
    name: "Circuit — Sydney",
    location: "Sydney, AUS",
    venue: "The Star",
    range: "Apr 1 – Apr 12",
    events: 10,
    status: "registering",
    accent: "oklch(0.45 0.09 305)",
  },
  {
    id: "circ-bra",
    year: 2026,
    name: "Circuit — São Paulo",
    location: "São Paulo, BRA",
    venue: "H2 Club",
    range: "Mar 10 – Mar 20",
    events: 12,
    status: "completed",
    accent: "oklch(0.45 0.09 50)",
  },
  {
    id: "wps25",
    year: 2025,
    name: "World Poker Series 2025",
    location: "Las Vegas, NV",
    venue: "Horseshoe & Paris",
    range: "May 28 – Jul 17",
    events: 99,
    status: "completed",
    accent: "oklch(0.40 0.04 60)",
  },
  {
    id: "wpse25",
    year: 2025,
    name: "World Poker Series Europe",
    location: "Rozvadov, CZE",
    venue: "King's Resort",
    range: "Oct 1 – Oct 22",
    events: 15,
    status: "completed",
    accent: "oklch(0.40 0.04 60)",
  },
  {
    id: "circ-ind",
    year: 2025,
    name: "Circuit — Indiana",
    location: "Hammond, IN",
    venue: "Horseshoe Indiana",
    range: "Jan 5 – Jan 16",
    events: 8,
    status: "completed",
    accent: "oklch(0.40 0.04 60)",
  },
  {
    id: "circ-atl",
    year: 2025,
    name: "Circuit — Atlantic City",
    location: "Atlantic City, NJ",
    venue: "Borgata",
    range: "Feb 10 – Feb 20",
    events: 6,
    status: "completed",
    accent: "oklch(0.40 0.04 60)",
  },
];

const EVENTS = [
  {
    no: 1, time: "03/31 12:00", name: "The Opener Mystery Bounty", buyin: "€1,100",
    game: "NLH", mode: "Single", entries: 894, reentries: 1298, unique: null,
    status: "running", featured: true,
  },
  {
    no: 2, time: "04/01 14:00", name: "PLO / PLO8 / Big O", buyin: "€600",
    game: "PLO", mode: "Choice", entries: 97, reentries: 84, unique: null,
    status: "registering",
  },
  {
    no: 3, time: "04/01 16:00", name: "Deepstack NLH", buyin: "€550",
    game: "NLH", mode: "Single", entries: 127, reentries: null, unique: null,
    status: "completed",
  },
  {
    no: 4, time: "04/02 12:00", name: "Pot-Limit Omaha Championship", buyin: "€2,200",
    game: "PLO", mode: "Single", entries: 312, reentries: 198, unique: null,
    status: "running",
  },
  {
    no: 5, time: "04/03 12:00", name: "Europe Main Event", buyin: "€5,300",
    game: "NLH", mode: "Single", entries: 1807, reentries: 838, unique: 1273,
    status: "running", featured: true,
  },
  {
    no: 6, time: "04/04 14:00", name: "Turbo NLH", buyin: "€600",
    game: "NLH", mode: "Single", entries: 78, reentries: 26, unique: null,
    status: "announced",
  },
  {
    no: 7, time: "04/05 12:00", name: "Omaha Hi-Lo 8/B", buyin: "€1,500",
    game: "O8", mode: "Fixed 6h", entries: null, reentries: null, unique: null,
    status: "announced",
  },
  {
    no: 8, time: "04/06 12:00", name: "High Roller NLH", buyin: "€10,000",
    game: "NLH", mode: "Single", entries: null, reentries: null, unique: null,
    status: "announced",
  },
  {
    no: 9, time: "04/06 19:00", name: "Mini Main Event", buyin: "€1,100",
    game: "NLH", mode: "Single", entries: null, reentries: null, unique: null,
    status: "announced",
  },
  {
    no: 14, time: "04/02 14:00", name: "Mixed PLO/Omaha/Big O", buyin: "€1,500",
    game: "MIX", mode: "Choice", entries: 412, reentries: 187, unique: null,
    status: "running", featured: true,
  },
];

const FLIGHTS = [
  { no: 5, name: "Day1A", time: "03/04 12:00", entries: "336 / 803", players: 667, tables: 136, status: "completed" },
  { no: 5, name: "Day1B", time: "04/04 12:00", entries: "269 / 653", players: 513, tables: 140, status: "completed" },
  { no: 5, name: "Day1C", time: "05/04 12:00", entries: "299 / 713", players: 559, tables: 154, status: "completed" },
  { no: 5, name: "Day2", time: "06/04 12:00", entries: "918 / 918", players: 918, tables: 124, status: "registering", active: true },
  { no: 5, name: "Day3", time: "07/04 12:00", entries: "0 / 0", players: 0, tables: 0, status: "announced" },
  { no: 5, name: "Day4", time: "08/04 12:00", entries: "0 / 0", players: 0, tables: 0, status: "announced" },
  { no: 5, name: "Day5", time: "09/04 12:00", entries: "0 / 0", players: 0, tables: 0, status: "announced" },
  { no: 5, name: "Final", time: "10/04 16:00", entries: "0 / 0", players: 0, tables: 0, status: "announced" },
];

// Seat states: 'a' active, 'e' empty, 'r' recently eliminated, 'd' dealer-only, 'w' waiting
const TABLES = [
  { id: "#071", featured: true, seats: ["a","a","a","a","a","a","a","a","a"], rfid: "rdy", deck: "52/52", out: "NDI", cc: "live", op: "Op.A · #47", marquee: true },
  { id: "#069", seats: ["a","a","a","a","e","a","a","a","r"], rfid: "off", deck: null, out: null, cc: "live", op: "Op.B · #23" },
  { id: "#070", seats: ["a","a","a","a","a","a","e","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#072", featured: true, seats: ["a","a","a","a","a","a","a","e","a"], rfid: "err", deck: "0/52", out: "SDI", cc: "err", op: "Op.C · ⚠RFID" },
  { id: "#073", seats: ["a","a","e","a","a","a","a","a","e"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#074", seats: ["a","a","a","a","a","a","a","a","e"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#075", seats: ["a","a","a","a","a","e","a","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#076", seats: ["a","a","a","a","a","a","a","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#077", seats: ["e","a","a","a","a","a","a","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#078", seats: ["a","a","a","a","a","a","r","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#079", seats: ["a","a","a","a","e","a","a","a","a"], rfid: "off", deck: null, out: null, cc: "idle" },
  { id: "#080", seats: ["a","a","a","a","a","a","a","e","a"], rfid: "off", deck: null, out: null, cc: "idle" },
];

const WAITLIST = [
  "Christopher Kearin", "Bence Fist", "Yuval Frome", "Ravi Guerin",
  "Paul Ephremsen", "Benedetta Šudice", "Ernest Grenier", "Naomi Dato",
  "Mirsha Mitev", "Tomáš Havel", "Karine Lévesque", "Adebayo Okafor",
];

const PLAYERS = [
  { place: 1,  name: "Daniel Negreanu",   country: "USA", flag: "🇺🇸", chips: 4317000, bb: 171.8, state: "active", vpip: 28, pfr: 19, agr: 3.2, ft: true,  featured: true },
  { place: 2,  name: "Romain Arnaud",     country: "FRA", flag: "🇫🇷", chips: 3850000, bb: 153.2, state: "active", vpip: 24, pfr: 16, agr: 2.8 },
  { place: 3,  name: "Phil Morrison",     country: "GBR", flag: "🇬🇧", chips: 2914000, bb: 115.9, state: "active", vpip: 31, pfr: 22, agr: 4.1 },
  { place: 4,  name: "Stefan Lehner",     country: "DEU", flag: "🇩🇪", chips: 2580000, bb: 102.6, state: "active", vpip: 22, pfr: 14, agr: 2.1 },
  { place: 5,  name: "Bryn Kenney",       country: "USA", flag: "🇺🇸", chips: 2310000, bb:  91.9, state: "active", vpip: 33, pfr: 25, agr: 4.5, ft: true,  featured: true },
  { place: 6,  name: "Yuri Martins",      country: "BRA", flag: "🇧🇷", chips: 1920000, bb:  76.4, state: "away",   vpip: 26, pfr: 18, agr: 3.0 },
  { place: 7,  name: "Naoki Ishibashi",   country: "JPN", flag: "🇯🇵", chips: 1640000, bb:  65.2, state: "active", vpip: 20, pfr: 12, agr: 1.8 },
  { place: 8,  name: "Oren Biton",        country: "ISR", flag: "🇮🇱", chips: 1450000, bb:  57.7, state: "active", vpip: 29, pfr: 20, agr: 3.5 },
  { place: 9,  name: "André Belley",      country: "CAN", flag: "🇨🇦", chips: 1280000, bb:  50.9, state: "active", vpip: 25, pfr: 17, agr: 2.6 },
  { place: 10, name: "Carlos Selfa",      country: "ESP", flag: "🇪🇸", chips: 1100000, bb:  43.8, state: "elim",   vpip: 35, pfr: 21, agr: 3.8 },
  { place: 11, name: "Elif Demir",        country: "TUR", flag: "🇹🇷", chips:  982000, bb:  39.0, state: "active", vpip: 23, pfr: 15, agr: 2.4 },
  { place: 12, name: "Rasmus Holst",      country: "DNK", flag: "🇩🇰", chips:  870000, bb:  34.6, state: "active", vpip: 27, pfr: 19, agr: 3.1 },
  { place: 13, name: "Ji-Hoon Park",      country: "KOR", flag: "🇰🇷", chips:  814000, bb:  32.4, state: "active", vpip: 30, pfr: 21, agr: 3.6 },
  { place: 14, name: "Ksenia Volkov",     country: "RUS", flag: "🇷🇺", chips:  742000, bb:  29.5, state: "active", vpip: 21, pfr: 13, agr: 1.9 },
  { place: 15, name: "Mateusz Cichocki",  country: "POL", flag: "🇵🇱", chips:  680000, bb:  27.0, state: "active", vpip: 26, pfr: 18, agr: 2.7 },
];

window.EBS_DATA = { SERIES, EVENTS, FLIGHTS, TABLES, WAITLIST, PLAYERS };
