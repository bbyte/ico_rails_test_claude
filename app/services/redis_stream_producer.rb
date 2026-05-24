class RedisStreamProducer
  STREAM_KEY = "rss:commands".freeze

  def initialize(redis: nil)
    @redis = redis || Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
  end

  def publish(job_id, urls)
    @redis.xadd(STREAM_KEY, { job_id: job_id, urls: urls.to_json })
  rescue Redis::BaseError => e
    raise ServiceError, "Redis stream publish failed: #{e.message}"
  end
end
