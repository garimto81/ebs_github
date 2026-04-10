import './DegradationBanner.css'

export type DegradationLevel = 'warn' | 'error' | 'readonly'

interface Props {
  level: DegradationLevel
  message: string
}

export default function DegradationBanner({ level, message }: Props) {
  return (
    <div className={`degradation-banner degradation-${level}`} role="alert">
      <span className="degradation-icon">
        {level === 'warn' ? '⚠' : level === 'error' ? '✕' : 'ℹ'}
      </span>
      <span className="degradation-message">{message}</span>
    </div>
  )
}
