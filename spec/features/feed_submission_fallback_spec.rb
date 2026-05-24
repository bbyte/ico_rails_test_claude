require "rails_helper"

RSpec.describe "Feed submission — fallback mode (Redis unavailable)",
               type: :feature, js: true, integration: true do
  fixtures :users

  before do
    `docker compose stop redis`
    browser_login_as users(:alice)
  end

  after { `docker compose start redis` }

  scenario "user submits URLs and gets results synchronously" do
    visit "/"
    fill_in "Feed URL 1", with: "https://feeds.bbci.co.uk/news/rss.xml"
    click_button "Parse Feeds"

    expect(page).to have_css("[data-status='done']", wait: 30)
    expect(page).to have_css(".feed-item", minimum: 1)
    expect(page).to have_css("[data-mode='fallback']")
  end

  scenario "health endpoint reports fallback mode" do
    visit "/api/v1/health"
    expect(page).to have_text('"mode":"fallback"')
  end
end
