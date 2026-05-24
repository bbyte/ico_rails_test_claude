const STATUS_CLASS = {
  pending:    "bg-warning text-dark",
  processing: "bg-info text-dark",
  done:       "bg-success",
  failed:     "bg-danger",
}

export function StatusBadge({ status }) {
  return (
    <span
      className={`badge ${STATUS_CLASS[status] ?? "bg-secondary"}`}
      data-status={status}
    >
      {status}
    </span>
  )
}
