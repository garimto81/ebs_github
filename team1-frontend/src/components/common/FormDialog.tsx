import type { ReactNode, FormEvent } from 'react'

interface FormDialogProps {
  open: boolean
  title: string
  children: ReactNode
  onSave: () => void
  onCancel: () => void
  saveLabel?: string
}

export default function FormDialog({
  open,
  title,
  children,
  onSave,
  onCancel,
  saveLabel = 'Save',
}: FormDialogProps) {
  if (!open) return null

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    onSave()
  }

  return (
    <div className="dialog-overlay" onClick={onCancel}>
      <div className="dialog dialog-form" onClick={(e) => e.stopPropagation()}>
        <h3 className="dialog-title">{title}</h3>
        <form onSubmit={handleSubmit}>
          <div className="dialog-body">{children}</div>
          <div className="dialog-actions">
            <button type="button" className="btn btn-secondary" onClick={onCancel}>Cancel</button>
            <button type="submit" className="btn btn-primary">{saveLabel}</button>
          </div>
        </form>
      </div>
    </div>
  )
}
