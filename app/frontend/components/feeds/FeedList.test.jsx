import { render, screen } from "@testing-library/react"
import { FeedList } from "./FeedList"

const makeRequest = (overrides = {}) => ({
  feed_request_id: 1,
  status: "done",
  mode: "full",
  items: [],
  errors: [],
  ...overrides,
})

test("renders empty state when no requests", () => {
  render(<FeedList requests={[]} />)
  expect(screen.getByText(/no feeds yet/i)).toBeInTheDocument()
})

test("renders feed items sorted by publish_date desc", () => {
  const items = [
    { title: "Older", link: "https://a.com/1", source: "S", source_url: "https://a.com", publish_date: "2026-05-20", description: "" },
    { title: "Newer", link: "https://a.com/2", source: "S", source_url: "https://a.com", publish_date: "2026-05-24", description: "" },
  ]
  const requests = [makeRequest({ items })]
  render(<FeedList requests={requests} />)
  const cards = screen.getAllByText(/Newer|Older/)
  expect(cards[0].textContent).toBe("Newer")
})

test("shows pending status badge", () => {
  render(<FeedList requests={[makeRequest({ status: "pending" })]} />)
  expect(screen.getByText("pending")).toBeInTheDocument()
})
