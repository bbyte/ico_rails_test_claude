import { useState, useEffect, useCallback } from "react"
import { LoginForm } from "./auth/LoginForm"
import { FeedForm } from "./feeds/FeedForm"
import { FeedList } from "./feeds/FeedList"
import { useFeedChannel } from "../hooks/useFeedChannel"
import { api } from "../api/client"

export default function App() {
  const [authenticated, setAuthenticated] = useState(null)
  const [requests, setRequests] = useState([])

  useEffect(() => {
    api.getFeedItems()
      .then((data) => {
        setAuthenticated(true)
        if (data.items?.length) {
          setRequests([{
            feed_request_id: "initial",
            status: "done",
            mode: "cached",
            items: data.items,
            errors: [],
          }])
        }
      })
      .catch(() => setAuthenticated(false))
  }, [])

  const handleCableMessage = useCallback((data) => {
    setRequests((prev) =>
      prev.map((r) =>
        r.feed_request_id === data.feed_request_id
          ? { ...r, status: data.status, items: data.items, errors: data.errors }
          : r
      )
    )
  }, [])

  useFeedChannel(handleCableMessage)

  const handleSubmit = (result) => {
    setRequests((prev) => [
      {
        feed_request_id: result.feed_request_id,
        status: result.status,
        mode: result.mode,
        items: result.items || [],
        errors: [],
      },
      ...prev,
    ])
  }

  const handleSignOut = async () => {
    await api.signOut().catch(() => {})
    setAuthenticated(false)
    setRequests([])
  }

  if (authenticated === null) {
    return <div className="container mt-5"><p>Loading…</p></div>
  }

  if (!authenticated) {
    return <LoginForm onLogin={() => setAuthenticated(true)} />
  }

  return (
    <div className="container mt-4">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1>RSS Reader</h1>
        <button className="btn btn-outline-secondary" onClick={handleSignOut}>
          Sign out
        </button>
      </div>
      <FeedForm onSubmit={handleSubmit} />
      <FeedList requests={requests} />
    </div>
  )
}
