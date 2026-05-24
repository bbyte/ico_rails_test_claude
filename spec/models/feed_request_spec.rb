require "rails_helper"

RSpec.describe FeedRequest, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:feed_items).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:status).in_array(FeedRequest::STATUSES) }
  it { is_expected.to validate_inclusion_of(:mode).in_array(FeedRequest::MODES) }

  describe "status transitions" do
    let(:user) { FactoryBot.create(:user) }
    let(:req)  { FactoryBot.create(:feed_request, user: user, status: "pending", urls: ["https://example.com/rss"]) }

    it "can transition to done" do
      req.update!(status: "done")
      expect(req.status).to eq("done")
    end

    it "rejects invalid status" do
      expect { req.update!(status: "unknown") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
