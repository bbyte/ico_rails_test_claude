require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1280,800")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver      = :chrome_headless
Capybara.default_driver         = :rack_test
Capybara.default_max_wait_time  = 10
Capybara.server_port            = 3001
Capybara.server_host            = "127.0.0.1"
Capybara.app_host               = "http://127.0.0.1:3001"

RSpec.configure do |config|
  config.include Capybara::DSL, type: :feature
  config.include Rails.application.routes.url_helpers, type: :feature

  config.before(:each, type: :feature) do
    Capybara.reset_sessions!
  end
end
