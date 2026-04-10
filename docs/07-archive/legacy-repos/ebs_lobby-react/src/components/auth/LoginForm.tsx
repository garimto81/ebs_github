import { useState, useEffect, useRef, type FormEvent } from 'react'
import { useAuthStore } from '../../store/auth-store'
import * as authApi from '../../api/auth'

type Step = 'login' | '2fa' | 'forgot'

interface LoginFormProps {
  onSuccess?: () => void
}

export default function LoginForm({ onSuccess }: LoginFormProps) {
  const [step, setStep] = useState<Step>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [totpCode, setTotpCode] = useState('')
  const [tempToken, setTempToken] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [twoFaFailCount, setTwoFaFailCount] = useState(0)
  const [twoFaCooldown, setTwoFaCooldown] = useState(0)
  const cooldownRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const login = useAuthStore((s) => s.login)
  const complete2fa = useAuthStore((s) => s.complete2fa)

  useEffect(() => {
    if (twoFaCooldown <= 0) {
      if (cooldownRef.current) clearInterval(cooldownRef.current)
      return
    }
    cooldownRef.current = setInterval(() => {
      setTwoFaCooldown((c) => {
        if (c <= 1) {
          if (cooldownRef.current) clearInterval(cooldownRef.current)
          setTwoFaFailCount(0)
          return 0
        }
        return c - 1
      })
    }, 1000)
    return () => { if (cooldownRef.current) clearInterval(cooldownRef.current) }
  }, [twoFaCooldown > 0]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleLogin = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      const result = await login(email, password)
      if (result.success) {
        onSuccess?.()
      } else if (result.requires2fa) {
        setTempToken(result.tempToken ?? '')
        setStep('2fa')
      } else {
        setError('Invalid email or password.')
      }
    } catch (err: unknown) {
      if (!navigator.onLine) {
        setError('Check your network connection.')
      } else if (err && typeof err === 'object' && 'status' in err) {
        const status = (err as { status: number }).status
        if (status === 401) setError('Invalid email or password.')
        else if (status === 429) setError('Too many login attempts. Please wait and try again.')
        else setError('Login failed. Please try again.')
      } else if (err instanceof Error && err.name === 'TimeoutError') {
        setError('Server response timed out.')
      } else {
        setError('Login failed. Please try again.')
      }
    }
    setLoading(false)
  }

  const handleVerify2fa = async (e: FormEvent) => {
    e.preventDefault()
    if (twoFaCooldown > 0) return
    setError(null)
    setLoading(true)
    try {
      const result = await complete2fa(tempToken, totpCode)
      if (result.success) {
        setTwoFaFailCount(0)
        onSuccess?.()
      } else {
        const newCount = twoFaFailCount + 1
        setTwoFaFailCount(newCount)
        if (newCount >= 3) {
          setTwoFaCooldown(30)
          setError('Too many failed attempts. Please wait 30 seconds.')
        } else {
          setError('Invalid 2FA code.')
        }
      }
    } catch {
      setError('Verification failed. Please try again.')
    }
    setTotpCode('')
    setLoading(false)
  }

  const handleForgotPassword = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setInfo(null)
    setLoading(true)
    try {
      const res = await authApi.forgotPassword(email)
      if (res.data) {
        setInfo('Password reset email sent. Check your inbox.')
      } else {
        setError('Failed to send reset email.')
      }
    } catch {
      setError('Failed to send reset email.')
    }
    setLoading(false)
  }

  // ── 2FA Step ──
  if (step === '2fa') {
    return (
      <form className="login-form" onSubmit={handleVerify2fa}>
        <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
          Enter the 6-digit code from your authenticator app.
        </p>
        <div className="form-group">
          <label htmlFor="totp">2FA Code</label>
          <input
            id="totp"
            type="text"
            inputMode="numeric"
            maxLength={6}
            value={totpCode}
            onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, ''))}
            required
            autoFocus
          />
        </div>
        {error && <div className="form-error">{error}</div>}
        <button type="submit" className="btn btn-primary btn-full" disabled={loading || totpCode.length !== 6 || twoFaCooldown > 0}>
          {twoFaCooldown > 0 ? `Wait ${twoFaCooldown}s` : loading ? 'Verifying...' : 'Verify'}
        </button>
        <button type="button" className="btn-link" onClick={() => { setStep('login'); setError(null) }}>
          Back to login
        </button>
      </form>
    )
  }

  // ── Forgot Password Step ──
  if (step === 'forgot') {
    return (
      <form className="login-form" onSubmit={handleForgotPassword}>
        <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
          Enter your email to receive a password reset link.
        </p>
        <div className="form-group">
          <label htmlFor="forgot-email">Email</label>
          <input
            id="forgot-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoFocus
          />
        </div>
        {error && <div className="form-error">{error}</div>}
        {info && <div className="form-info">{info}</div>}
        <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
          {loading ? 'Sending...' : 'Send Reset Link'}
        </button>
        <button type="button" className="btn-link" onClick={() => { setStep('login'); setError(null); setInfo(null) }}>
          Back to login
        </button>
      </form>
    )
  }

  // ── Login Step (default) ──
  return (
    <form className="login-form" onSubmit={handleLogin}>
      <div className="form-group">
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="email"
        />
      </div>
      <div className="form-group">
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          autoComplete="current-password"
        />
      </div>
      {error && <div className="form-error">{error}</div>}
      <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
        {loading ? 'Signing in...' : 'Sign In'}
      </button>
      <div style={{ textAlign: 'right', marginTop: 4 }}>
        <button type="button" className="btn-link" onClick={() => { setStep('forgot'); setError(null) }}>
          Forgot your password?
        </button>
      </div>
    </form>
  )
}
