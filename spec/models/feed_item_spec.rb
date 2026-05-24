require "rails_helper"

RSpec.describe FeedItem, type: :model do
  subject { FactoryBot.build(:feed_item, feed_request: FactoryBot.create(:feed_request)) }

  it { is_expected.to belong_to(:feed_request) }
  it { is_expected.to validate_presence_of(:link) }
  it { is_expected.to validate_uniqueness_of(:link).scoped_to(:feed_request_id) }

  describe ".sorted" do
    let(:user) { FactoryBot.create(:user) }
    let(:req)  { FactoryBot.create(:feed_request, user: user, urls: ["https://example.com"]) }

    it "orders by publish_date descending" do
      older = FactoryBot.create(:feed_item, feed_request: req, publish_date: "2026-05-20", link: "https://a.com/1")
      newer = FactoryBot.create(:feed_item, feed_request: req, publish_date: "2026-05-24", link: "https://a.com/2")
      expect(FeedItem.sorted.map(&:id)).to eq([newer.id, older.id])
    end
  end
end
