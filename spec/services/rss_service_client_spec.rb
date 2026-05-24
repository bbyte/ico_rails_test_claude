require "rails_helper"
require "webmock/rspec"

RSpec.describe RssServiceClient do
  let(:base_url) { "http://rss_service:8080" }
  let(:jwt)      { "test-jwt-token" }
  let(:client)   { described_class.new(jwt: jwt) }

  describe "#parse" do
    let(:urls)   { [ "https://feeds.bbci.co.uk/news/rss.xml" ] }
    let(:job_id) { "job-abc-123" }

    context "when done on first poll" do
      before do
        stub_request(:post, "#{base_url}/parse")
          .to_return(status: 200, body: { job_id: job_id }.to_json, headers: { "Content-Type" => "application/json" })

        stub_request(:get, "#{base_url}/jobs/#{job_id}")
          .to_return(
            status: 200,
            body: { status: "done", items: [ { title: "Test", link: "https://bbc.co.uk/1" } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns items" do
        items = client.parse(urls)
        expect(items).to include(a_hash_including("title" => "Test"))
      end
    end

    context "when status is failed" do
      before do
        stub_request(:post, "#{base_url}/parse")
          .to_return(status: 200, body: { job_id: job_id }.to_json, headers: { "Content-Type" => "application/json" })

        stub_request(:get, "#{base_url}/jobs/#{job_id}")
          .to_return(
            status: 200,
            body: { status: "failed", error: "invalid feed" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises ServiceError" do
        expect { client.parse(urls) }.to raise_error(RssServiceClient::ServiceError, /invalid feed/)
      end
    end

    context "when job times out" do
      before do
        stub_request(:post, "#{base_url}/parse")
          .to_return(status: 200, body: { job_id: job_id }.to_json, headers: { "Content-Type" => "application/json" })

        stub_request(:get, "#{base_url}/jobs/#{job_id}")
          .to_return(
            status: 200,
            body: { status: "processing" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      before { allow(client).to receive(:sleep) }

      it "raises ServiceError after exhausting polls" do
        stub_const("RssServiceClient::POLL_ATTEMPTS", 2)
        stub_const("RssServiceClient::POLL_INTERVAL", 0)
        expect { client.parse(urls) }.to raise_error(RssServiceClient::ServiceError, /timed out/)
      end
    end

    context "when parse endpoint returns non-2xx" do
      before do
        stub_request(:post, "#{base_url}/parse")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises ServiceError" do
        expect { client.parse(urls) }.to raise_error(RssServiceClient::ServiceError)
      end
    end
  end
end
