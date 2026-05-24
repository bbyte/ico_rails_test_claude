FactoryBot.define do
  factory :feed_item do
    association :feed_request
    title        { "Test Item" }
    source       { "Test Feed" }
    source_url   { "https://example.com/rss" }
    sequence(:link) { |n| "https://example.com/item/#{n}" }
    publish_date { Date.current }
    description  { "Test description." }
  end
end
