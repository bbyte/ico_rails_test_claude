import { useEffect } from "react"
import consumer from "../cable"

export function useFeedChannel(onMessage) {
  useEffect(() => {
    const subscription = consumer.subscriptions.create("FeedChannel", {
      received(data) {
        onMessage(data)
      },
    })
    return () => subscription.unsubscribe()
  }, [])
}
