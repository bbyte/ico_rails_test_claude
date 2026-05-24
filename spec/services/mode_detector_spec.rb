require "rails_helper"

RSpec.describe ModeDetector do
  describe ".current" do
    it "returns 'full' when Redis responds with PONG" do
      redis = instance_double(Redis, ping: "PONG")
      allow(Redis).to receive(:new).and_return(redis)
      expect(described_class.current).to eq("full")
    end

    it "returns 'fallback' when Redis raises" do
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError, "connection refused")
      expect(described_class.current).to eq("fallback")
    end
  end
end
