class FeedChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user
    stream_from "feed_#{current_user.id}" if current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
