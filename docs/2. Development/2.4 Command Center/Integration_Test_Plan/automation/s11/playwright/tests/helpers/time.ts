export function todayStartIso(tz = 'Asia/Seoul'): string {
  const now = new Date();
  const local = new Date(now.toLocaleString('en-US', { timeZone: tz }));
  local.setHours(0, 0, 0, 0);
  return local.toISOString();
}

export function yesterdayStartIso(tz = 'Asia/Seoul'): string {
  const d = new Date();
  const local = new Date(d.toLocaleString('en-US', { timeZone: tz }));
  local.setDate(local.getDate() - 1);
  local.setHours(0, 0, 0, 0);
  return local.toISOString();
}

export function yesterdayEndIso(tz = 'Asia/Seoul'): string {
  const d = new Date();
  const local = new Date(d.toLocaleString('en-US', { timeZone: tz }));
  local.setDate(local.getDate() - 1);
  local.setHours(23, 59, 59, 999);
  return local.toISOString();
}
