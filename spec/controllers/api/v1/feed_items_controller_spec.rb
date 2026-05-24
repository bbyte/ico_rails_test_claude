require "rails_helper"

RSpec.describe Api::V1::FeedItemsController, type: :controller do
  let(:alice) { FactoryBot.create(:user) }
  let(:bob)   { FactoryBot.create(:user) }

  before { sign_in alice }

  describe "GET #index" do
    let!(:alice_req) { FactoryBot.create(:feed_request, user: alice, urls: [ "https://example.com" ]) }
    let!(:alice_item) { FactoryBot.create(:feed_item, feed_request: alice_req, link: "https://a.com/1") }
    let!(:bob_req)   { FactoryBot.create(:feed_request, user: bob, urls: [ "https://other.com" ]) }
    let!(:bob_item)  { FactoryBot.create(:feed_item, feed_request: bob_req, link: "https://b.com/1") }

    it "returns only Alice's items" do
      get :index
      expect(response).to have_http_status(:ok)
      items = JSON.parse(response.body)["items"]
      links = items.map { |i| i["link"] }
      expect(links).to include("https://a.com/1")
      expect(links).not_to include("https://b.com/1")
    end

    context "when unauthenticated" do
      before { sign_out alice }

      it "returns 401" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
