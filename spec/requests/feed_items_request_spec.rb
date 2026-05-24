require "rails_helper"

RSpec.describe "GET /api/v1/feed_items", type: :request do
  let(:alice) { FactoryBot.create(:user) }
  let(:bob)   { FactoryBot.create(:user) }

  context "when authenticated as alice" do
    before do
      sign_in alice
      req = FactoryBot.create(:feed_request, user: alice, urls: ["https://example.com"])
      FactoryBot.create(:feed_item, feed_request: req, link: "https://a.com/1", publish_date: "2026-05-23", title: "Newer")
      FactoryBot.create(:feed_item, feed_request: req, link: "https://a.com/2", publish_date: "2026-05-22", title: "Older")
    end

    it "returns alice's feed items" do
      get "/api/v1/feed_items"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["items"].length).to eq(2)
    end

    it "returns items sorted by publish_date descending" do
      get "/api/v1/feed_items"
      dates = JSON.parse(response.body)["items"].map { |i| Date.parse(i["publish_date"]) }
      expect(dates).to eq(dates.sort.reverse)
    end

    it "returns correct item fields" do
      get "/api/v1/feed_items"
      item = JSON.parse(response.body)["items"].first
      expect(item.keys).to match_array(%w[title source source_url link publish_date description])
    end
  end

  context "when authenticated as bob (no items)" do
    before { sign_in bob }

    it "returns an empty items array" do
      get "/api/v1/feed_items"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["items"]).to eq([])
    end
  end

  context "when unauthenticated" do
    it "returns 401" do
      get "/api/v1/feed_items"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
