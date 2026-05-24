require "rails_helper"

RSpec.describe FeedChannel, type: :channel do
  let(:user) { FactoryBot.create(:user) }

  describe "#subscribed" do
    it "subscribes to the user's feed stream" do
      stub_connection current_user: user
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription.streams).to include("feed_#{user.id}")
    end
  end

  describe "unauthenticated connection" do
    it "rejects the subscription" do
      stub_connection current_user: nil
      subscribe
      expect(subscription).to be_rejected
    end
  end
end
