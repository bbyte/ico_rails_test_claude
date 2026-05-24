RSpec.configure do |config|
  config.include Warden::Test::Helpers

  config.before(:each, type: :feature) do
    Warden.test_mode!
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end

def sign_in_as(user)
  login_as(user, scope: :user)
end

# Use this for js: true (Selenium) specs — Warden test mode doesn't cross thread boundaries.
def browser_login_as(user, password: "password")
  visit "/"
  fill_in "Email", with: user.email
  fill_in "Password", with: password
  click_button "Sign in"
  expect(page).to have_button("Sign out", wait: 10)
end
