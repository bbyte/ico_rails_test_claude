export function FeedItem({ item }) {
  const { title, source, source_url, link, publish_date, description } = item
  const truncated = description?.length > 200
    ? description.slice(0, 200) + "…"
    : description

  return (
    <div className="card mb-3 feed-item">
      <div className="card-body">
        <h5 className="card-title">{title}</h5>
        <p className="card-text text-muted small">
          <a href={source_url} target="_blank" rel="noreferrer">{source}</a>
        </p>
        <p className="card-text">{truncated}</p>
      </div>
      <div className="card-footer d-flex justify-content-between align-items-center">
        <span data-publish-date={publish_date}>{publish_date}</span>
        <a href={link} className="btn btn-sm btn-outline-primary" target="_blank" rel="noreferrer">
          Read more
        </a>
      </div>
    </div>
  )
}
