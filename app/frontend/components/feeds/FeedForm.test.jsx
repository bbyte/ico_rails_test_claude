import { render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { FeedForm } from "./FeedForm"

jest.mock("../../api/client", () => ({
  api: {
    submitFeeds: jest.fn(),
  },
}))

import { api } from "../../api/client"

afterEach(() => jest.resetAllMocks())

test("renders a URL input and submit button", () => {
  render(<FeedForm onSubmit={() => {}} />)
  expect(screen.getByRole("textbox")).toBeInTheDocument()
  expect(screen.getByRole("button", { name: /parse feeds/i })).toBeInTheDocument()
})

test("adds URL inputs when clicking 'Add another URL'", async () => {
  render(<FeedForm onSubmit={() => {}} />)
  expect(screen.getAllByRole("textbox")).toHaveLength(1)

  await userEvent.click(screen.getByRole("button", { name: /add another url/i }))
  expect(screen.getAllByRole("textbox")).toHaveLength(2)
})

test("disables submit when all inputs are empty", () => {
  render(<FeedForm onSubmit={() => {}} />)
  expect(screen.getByRole("button", { name: /parse feeds/i })).toBeDisabled()
})

test("enables submit when at least one URL is filled", async () => {
  render(<FeedForm onSubmit={() => {}} />)
  await userEvent.type(screen.getByRole("textbox"), "https://example.com/rss")
  expect(screen.getByRole("button", { name: /parse feeds/i })).not.toBeDisabled()
})

test("calls onSubmit with API result", async () => {
  const result = { feed_request_id: 1, status: "pending", mode: "full" }
  api.submitFeeds.mockResolvedValue(result)
  const onSubmit = jest.fn()
  render(<FeedForm onSubmit={onSubmit} />)

  await userEvent.type(screen.getByRole("textbox"), "https://example.com/rss")
  await userEvent.click(screen.getByRole("button", { name: /parse feeds/i }))

  await waitFor(() => {
    expect(api.submitFeeds).toHaveBeenCalledWith(["https://example.com/rss"])
    expect(onSubmit).toHaveBeenCalledWith(result)
  })
})
