require "rails_helper"

RSpec.describe RedisStreamProducer do
  let(:redis) { instance_double(Redis) }
  let(:producer) { described_class.new(redis: redis) }

  describe "#publish" do
    it "calls XADD with job_id and urls" do
      allow(redis).to receive(:xadd).and_return("1-0")
      producer.publish("job-123", ["https://example.com/rss"])
      expect(redis).to have_received(:xadd).with(
        "rss:commands",
        { job_id: "job-123", urls: '["https://example.com/rss"]' }
      )
    end

    it "raises ServiceError when Redis fails" do
      allow(redis).to receive(:xadd).and_raise(Redis::BaseError, "ERR")
      expect { producer.publish("job-123", []) }.to raise_error(ServiceError)
    end
  end
end
