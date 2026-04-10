const STATUS_COLORS: Record<string, string> = {
  empty: '#71717a',
  setup: '#f59e0b',
  live: '#22c55e',
  paused: '#f97316',
  closed: '#ef4444',
  vacant: '#71717a',
  occupied: '#3b82f6',
  busted: '#ef4444',
  created: '#71717a',
  announced: '#8b5cf6',
  registering: '#3b82f6',
  running: '#22c55e',
  completed: '#6b7280',
}

interface StatusBadgeProps {
  status: string
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const color = STATUS_COLORS[status] || '#71717a'

  return (
    <span
      className="status-badge"
      style={{ backgroundColor: `${color}20`, color, borderColor: `${color}40` }}
    >
      {status}
    </span>
  )
}
