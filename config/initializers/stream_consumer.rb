return unless Rails.env.production? || ENV["ENABLE_STREAM_CONSUMER"] == "1"
return if ENV["DISABLE_STREAM_CONSUMER"] == "1"

Rails.application.config.after_initialize do
  Thread.new do
    redis_url    = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
    redis        = Redis.new(url: redis_url)
    group_name   = "rss-rails-workers"
    stream_key   = "rss:results"
    worker_name  = "worker-#{Process.pid}"

    begin
      redis.xgroup(:create, stream_key, group_name, "$", mkstream: true)
    rescue Redis::CommandError => e
      raise unless e.message.include?("BUSYGROUP")
    end

    loop do
      begin
        messages = redis.xreadgroup(group_name, worker_name, stream_key, ">", count: 10, block: 5000)
        next unless messages

        messages.each do |_stream, entries|
          entries.each do |msg_id, fields|
            begin
              job_id  = fields["job_id"]
              request = FeedRequest.find_by(job_id: job_id)
              next unless request

              items  = JSON.parse(fields["items"]  || "[]")
              errors = JSON.parse(fields["errors"] || "[]")
              status = fields["status"] || "done"

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
              request.update!(status: status)

              ActionCable.server.broadcast(
                "feed_#{request.user_id}",
                { feed_request_id: request.id, status: status, items: items, errors: errors }
              )

              redis.xack(stream_key, group_name, msg_id)
            rescue StandardError => e
              Rails.logger.error({ event: "stream_consumer_message_error", error: e.message }.to_json)
            end
          end
        end
      rescue Redis::BaseError => e
        Rails.logger.error({ event: "stream_consumer_redis_error", error: e.message }.to_json)
        sleep 5
      end
    end
  end
end
