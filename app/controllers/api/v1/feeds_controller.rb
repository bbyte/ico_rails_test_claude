module Api
  module V1
    class FeedsController < Api::BaseController
      def create
        urls = params[:urls]
        return render json: { error: "urls must be a non-empty array" }, status: :unprocessable_entity if urls.blank?

        mode = ModeDetector.current

        if mode == ModeDetector::FULL
          create_full(urls)
        else
          create_fallback(urls)
        end
      end

      private

      def create_full(urls)
        job_id  = SecureRandom.uuid
        request = current_user.feed_requests.create!(
          job_id: job_id, urls: urls, status: "pending", mode: "full"
        )
        RedisStreamProducer.new.publish(job_id, urls)
        render json: {
          feed_request_id: request.id,
          job_id: job_id,
          status: "pending",
          mode: "full"
        }, status: :accepted
      rescue ServiceError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      def create_fallback(urls)
        jwt    = current_user_jwt
        client = RssServiceClient.new(jwt: jwt)
        items  = client.parse(urls)

        request = current_user.feed_requests.create!(
          job_id: SecureRandom.uuid, urls: urls, status: "done", mode: "fallback"
        )
        feed_items = items.map do |item|
          {
            feed_request_id: request.id,
            title: item["title"],
            source: item["source"],
            source_url: item["source_url"],
            link: item["link"],
            publish_date: item["publish_date"],
            description: item["description"],
            created_at: Time.current,
            updated_at: Time.current
          }
        end
        FeedItem.insert_all(feed_items) if feed_items.any?

        render json: {
          feed_request_id: request.id,
          job_id: request.job_id,
          status: "done",
          mode: "fallback",
          items: feed_items.map { |i| i.except(:feed_request_id, :created_at, :updated_at) }
        }, status: :created
      rescue RssServiceClient::ServiceError => e
        render json: { error: e.message }, status: :service_unavailable
      end
    end
  end
end
