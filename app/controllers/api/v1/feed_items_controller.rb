module Api
  module V1
    class FeedItemsController < Api::BaseController
      def index
        items = FeedItem
          .joins(:feed_request)
          .where(feed_requests: { user_id: current_user.id })
          .sorted
          .map { |i| { title: i.title, source: i.source, source_url: i.source_url, link: i.link, publish_date: i.publish_date, description: i.description } }

        render json: { items: items }
      end
    end
  end
end
