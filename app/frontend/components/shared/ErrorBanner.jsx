import { useState } from "react"

export function ErrorBanner({ errors }) {
  const [dismissed, setDismissed] = useState(false)
  if (dismissed || !errors?.length) return null

  return (
    <div className="alert alert-warning alert-dismissible error-banner" role="alert">
      <strong>Some feeds had errors:</strong>
      <ul className="mb-0 mt-1">
        {errors.map((e, i) => <li key={i}>{e}</li>)}
      </ul>
      <button
        type="button"
        className="btn-close"
        aria-label="Close"
        onClick={() => setDismissed(true)}
      />
    </div>
  )
}
