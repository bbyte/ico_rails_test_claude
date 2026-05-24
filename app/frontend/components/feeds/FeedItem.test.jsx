import { render, screen } from "@testing-library/react"
import { FeedItem } from "./FeedItem"

const item = {
  title: "Breaking News",
  source: "BBC News",
  source_url: "https://feeds.bbci.co.uk/news/rss.xml",
  link: "https://bbc.co.uk/news/1",
  publish_date: "2026-05-23",
  description: "Something happened today.",
}

test("renders title, source, date, and description", () => {
  render(<FeedItem item={item} />)
  expect(screen.getByText("Breaking News")).toBeInTheDocument()
  expect(screen.getByText("BBC News")).toBeInTheDocument()
  expect(screen.getByText("2026-05-23")).toBeInTheDocument()
  expect(screen.getByText("Something happened today.")).toBeInTheDocument()
})

test("renders 'Read more' link pointing to item link", () => {
  render(<FeedItem item={item} />)
  const link = screen.getByRole("link", { name: /read more/i })
  expect(link).toHaveAttribute("href", item.link)
})

test("truncates long descriptions at 200 chars", () => {
  const longItem = { ...item, description: "a".repeat(250) }
  render(<FeedItem item={longItem} />)
  const text = screen.getByText(/a+…/)
  expect(text.textContent.length).toBeLessThanOrEqual(204)
})
