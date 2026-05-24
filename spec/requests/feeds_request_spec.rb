require "rails_helper"

RSpec.describe "POST /api/v1/feeds", type: :request do
  let(:user)    { FactoryBot.create(:user) }
  let(:headers) { { "Content-Type" => "application/json" } }

  context "when authenticated" do
    before { sign_in user }

    context "full mode (Redis available)" do
      before do
        allow(ModeDetector).to receive(:current).and_return("full")
        allow_any_instance_of(RedisStreamProducer).to receive(:publish).and_return("1-0")
      end

      it "returns 202 with job_id" do
        post "/api/v1/feeds", params: { urls: [ "https://feeds.bbci.co.uk/news/rss.xml" ] }.to_json, headers: headers
        expect(response).to have_http_status(:accepted)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("pending")
        expect(body["job_id"]).to be_present
        expect(body["mode"]).to eq("full")
      end

      it "creates a FeedRequest record" do
        expect {
          post "/api/v1/feeds", params: { urls: [ "https://example.com/rss" ] }.to_json, headers: headers
        }.to change(FeedRequest, :count).by(1)
        expect(FeedRequest.last.status).to eq("pending")
      end
    end

    context "fallback mode (Redis unavailable)" do
      let(:items) do
        [ { "title" => "Test", "link" => "https://example.com/1",
           "source" => "Test Feed", "source_url" => "https://example.com/rss",
           "publish_date" => "2026-05-23", "description" => "Test desc" } ]
      end

      before do
        allow(ModeDetector).to receive(:current).and_return("fallback")
        allow_any_instance_of(RssServiceClient).to receive(:parse).and_return(items)
      end

      it "returns 201 with items inline" do
        post "/api/v1/feeds", params: { urls: [ "https://example.com/rss" ] }.to_json, headers: headers
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("done")
        expect(body["mode"]).to eq("fallback")
        expect(body["items"].length).to eq(1)
      end

      it "persists items to the database" do
        post "/api/v1/feeds", params: { urls: [ "https://example.com/rss" ] }.to_json, headers: headers
        expect(FeedItem.count).to eq(1)
        expect(FeedItem.last.title).to eq("Test")
      end
    end

    it "returns 422 when urls is empty" do
      post "/api/v1/feeds", params: { urls: [] }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when urls is missing" do
      post "/api/v1/feeds", params: {}.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when unauthenticated" do
    it "returns 401" do
      post "/api/v1/feeds", params: { urls: [ "https://example.com/rss" ] }.to_json, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
