import { useState } from "react"
import { api } from "../../api/client"

export function FeedForm({ onSubmit }) {
  const [urls, setUrls] = useState([""])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const addUrl = () => setUrls((prev) => [...prev, ""])

  const removeUrl = (i) =>
    setUrls((prev) => prev.filter((_, idx) => idx !== i))

  const updateUrl = (i, val) =>
    setUrls((prev) => prev.map((u, idx) => (idx === i ? val : u)))

  const handleSubmit = async (e) => {
    e.preventDefault()
    const filled = urls.filter(Boolean)
    if (!filled.length) return
    setLoading(true)
    setError(null)
    try {
      const result = await api.submitFeeds(filled)
      onSubmit(result)
      setUrls([""])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mb-4">
      {urls.map((url, i) => (
        <div key={i} className="input-group mb-2">
          <input
            type="url"
            className="form-control"
            placeholder="https://example.com/feed.rss"
            value={url}
            onChange={(e) => updateUrl(i, e.target.value)}
            aria-label={`Feed URL ${i + 1}`}
          />
          {urls.length > 1 && (
            <button
              type="button"
              className="btn btn-outline-secondary"
              onClick={() => removeUrl(i)}
            >
              Remove
            </button>
          )}
        </div>
      ))}
      {error && <div className="alert alert-danger">{error}</div>}
      <div className="d-flex gap-2">
        <button
          type="button"
          className="btn btn-outline-secondary"
          onClick={addUrl}
        >
          Add another URL
        </button>
        <button
          type="submit"
          className="btn btn-primary"
          disabled={loading || urls.every((u) => !u)}
        >
          {loading ? "Parsing…" : "Parse Feeds"}
        </button>
      </div>
    </form>
  )
}
