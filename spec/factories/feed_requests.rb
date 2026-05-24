FactoryBot.define do
  factory :feed_request do
    association :user
    sequence(:job_id) { |n| "job-#{n}" }
    urls { ["https://example.com/rss"] }
    status { "pending" }
    mode   { "full" }
  end
end
