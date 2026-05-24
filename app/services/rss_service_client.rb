class RssServiceClient
  BASE_URL = ENV.fetch("RSS_SERVICE_URL", "http://rss_service:8080")
  POLL_ATTEMPTS = 10
  POLL_INTERVAL = 1

  ServiceError = Class.new(StandardError)

  def initialize(jwt:)
    @jwt = jwt
  end

  def parse(urls)
    response = HTTP
      .auth("Bearer #{@jwt}")
      .timeout(30)
      .post("#{BASE_URL}/parse", json: { urls: urls })

    raise ServiceError, "rss_service error: #{response.body}" unless response.status.success?

    job_id = response.parse["job_id"]
    poll_until_done(job_id)
  end

  private

  def poll_until_done(job_id)
    POLL_ATTEMPTS.times do
      res  = HTTP.auth("Bearer #{@jwt}").timeout(10).get("#{BASE_URL}/jobs/#{job_id}")
      body = res.parse
      return body["items"] if body["status"] == "done"
      raise ServiceError, body["error"] if body["status"] == "failed"
      sleep POLL_INTERVAL
    end
    raise ServiceError, "job #{job_id} timed out after #{POLL_ATTEMPTS} attempts"
  end
end
