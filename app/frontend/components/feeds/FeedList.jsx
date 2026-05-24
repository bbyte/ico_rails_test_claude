import { StatusBadge } from "../shared/StatusBadge"
import { ErrorBanner } from "../shared/ErrorBanner"
import { FeedItem } from "./FeedItem"

export function FeedList({ requests }) {
  if (!requests?.length) {
    return <p className="text-muted">No feeds yet. Submit some URLs above to get started.</p>
  }

  return (
    <div>
      {requests.map((req) => (
        <div key={req.feed_request_id} className="mb-4">
          <div className="d-flex align-items-center gap-2 mb-2">
            <StatusBadge status={req.status} />
            <span className="badge bg-secondary" data-mode={req.mode}>{req.mode}</span>
          </div>
          <ErrorBanner errors={req.errors} />
          {[...(req.items ?? [])].sort((a, b) => new Date(b.publish_date) - new Date(a.publish_date)).map((item) => (
            <FeedItem key={item.link} item={item} />
          ))}
        </div>
      ))}
    </div>
  )
}
