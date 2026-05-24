require "rails_helper"

RSpec.describe "Authentication", type: :feature, js: true do
  fixtures :users

  scenario "user can log in with valid credentials" do
    visit "/"
    fill_in "Email",    with: users(:alice).email
    fill_in "Password", with: "password"
    click_button "Sign in"

    expect(page).to have_text("RSS Reader")
  end

  scenario "user sees error with invalid credentials" do
    visit "/"
    fill_in "Email",    with: "wrong@example.com"
    fill_in "Password", with: "wrong"
    click_button "Sign in"

    expect(page).to have_text("Invalid email or password")
  end

  scenario "user can log out" do
    browser_login_as users(:alice)
    click_button "Sign out"

    expect(page).to have_field("Email")
  end
end
