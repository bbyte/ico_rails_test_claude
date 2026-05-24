class ModeDetector
  FULL     = "full".freeze
  FALLBACK = "fallback".freeze

  def self.current
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")).ping == "PONG" ? FULL : FALLBACK
  rescue StandardError => e
    Rails.logger.warn({ event: "redis_unavailable", error: e.message }.to_json)
    FALLBACK
  end
end
