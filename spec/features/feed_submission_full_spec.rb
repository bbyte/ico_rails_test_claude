require "rails_helper"

RSpec.describe "Feed submission — full mode (Redis + rss_service)",
               type: :feature, js: true, integration: true do
  fixtures :users

  before { browser_login_as users(:alice) }

  scenario "user submits a URL and sees parsed items via ActionCable" do
    visit "/"
    fill_in "Feed URL 1", with: "https://feeds.bbci.co.uk/news/rss.xml"
    click_button "Parse Feeds"

    expect(page).to have_css("[data-status='pending']")

    using_wait_time(15) do
      expect(page).to have_css("[data-status='done']")
      expect(page).to have_css(".feed-item", minimum: 1)
    end

    expect(FeedItem.count).to be > 0
  end

  scenario "items are sorted newest first" do
    visit "/"
    fill_in "Feed URL 1", with: "https://feeds.bbci.co.uk/news/rss.xml"
    click_button "Parse Feeds"

    using_wait_time(15) do
      expect(page).to have_css("[data-status='done']")
    end

    dates = all(".feed-item [data-publish-date]").map { |el| Date.parse(el["data-publish-date"]) }
    expect(dates).to eq(dates.sort.reverse)
  end
end
