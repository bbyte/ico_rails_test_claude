require "rails_helper"

RSpec.describe Api::V1::FeedsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  describe "POST #create" do
    context "full mode" do
      before do
        allow(ModeDetector).to receive(:current).and_return("full")
        allow_any_instance_of(RedisStreamProducer).to receive(:publish).and_return("1-0")
      end

      it "returns 202 with pending status" do
        post :create, params: { urls: [ "https://feeds.bbci.co.uk/news/rss.xml" ] }
        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)["status"]).to eq("pending")
      end

      it "creates a FeedRequest" do
        expect {
          post :create, params: { urls: [ "https://example.com/rss" ] }
        }.to change(FeedRequest, :count).by(1)
      end
    end

    context "fallback mode" do
      let(:items) { [ { "title" => "Test", "link" => "https://example.com/1", "source" => "Test", "source_url" => "https://example.com", "publish_date" => "2026-05-23", "description" => "desc" } ] }

      before do
        allow(ModeDetector).to receive(:current).and_return("fallback")
        allow_any_instance_of(RssServiceClient).to receive(:parse).and_return(items)
      end

      it "returns 201 with items" do
        post :create, params: { urls: [ "https://example.com/rss" ] }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("done")
        expect(body["mode"]).to eq("fallback")
      end
    end

    it "returns 422 when urls is empty" do
      post :create, params: { urls: [] }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when urls is missing" do
      post :create, params: {}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when unauthenticated" do
    before { sign_out user }

    it "returns 401" do
      post :create, params: { urls: [ "https://example.com/rss" ] }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
