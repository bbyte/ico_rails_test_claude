require "rails_helper"

RSpec.describe "Feed items display", type: :feature, js: true do
  fixtures :users, :feed_requests, :feed_items

  before { browser_login_as users(:alice) }

  scenario "user sees their cached feed items" do
    visit "/"
    expect(page).to have_css(".feed-item", count: 2)
    expect(page).to have_text("Breaking News")
    expect(page).to have_text("Other Story")
  end

  scenario "items are displayed with correct fields" do
    visit "/"
    within(".feed-item", text: "Breaking News") do
      expect(page).to have_text("BBC News")
      expect(page).to have_text("2026-05-23")
      expect(page).to have_text("Something happened today")
      expect(page).to have_link("Read more", href: "https://bbc.co.uk/news/1")
    end
  end

  scenario "items from other users are not visible" do
    visit "/"
    click_button "Sign out"
    expect(page).to have_field("Email", wait: 10)  # wait for sign-out to complete
    visit "/"  # reload to get fresh CSRF token for the new session
    fill_in "Email", with: users(:bob).email
    fill_in "Password", with: "password"
    click_button "Sign in"
    expect(page).to have_text("No feeds yet", wait: 10)
  end

  scenario "items are sorted newest first" do
    visit "/"
    expect(page).to have_css(".feed-item", count: 2)
    titles = all(".feed-item .card-title").map(&:text)
    expect(titles).to eq([ "Breaking News", "Other Story" ])
  end
end
