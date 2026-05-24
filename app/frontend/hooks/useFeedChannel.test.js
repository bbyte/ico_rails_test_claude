import { renderHook } from "@testing-library/react"
import { useFeedChannel } from "./useFeedChannel"

const mockUnsubscribe = jest.fn()
const mockCreate = jest.fn()
let capturedCallbacks = {}

jest.mock("../cable", () => ({
  __esModule: true,
  default: {
    subscriptions: {
      create: (channel, callbacks) => {
        mockCreate(channel)
        capturedCallbacks = callbacks
        return { unsubscribe: mockUnsubscribe }
      },
    },
  },
}))

afterEach(() => {
  jest.resetAllMocks()
  capturedCallbacks = {}
})

test("subscribes to FeedChannel on mount", () => {
  renderHook(() => useFeedChannel(jest.fn()))
  expect(mockCreate).toHaveBeenCalledWith("FeedChannel")
})

test("calls onMessage when data is received", () => {
  const onMessage = jest.fn()
  renderHook(() => useFeedChannel(onMessage))
  capturedCallbacks.received({ status: "done" })
  expect(onMessage).toHaveBeenCalledWith({ status: "done" })
})

test("unsubscribes on unmount", () => {
  const { unmount } = renderHook(() => useFeedChannel(jest.fn()))
  unmount()
  expect(mockUnsubscribe).toHaveBeenCalledTimes(1)
})
