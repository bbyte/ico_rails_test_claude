source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# Auth
gem "devise"
gem "bcrypt", "~> 3.1.7"

# Views
gem "slim-rails"

# Frontend build
gem "vite_rails"

# Redis / ActionCable
gem "redis", "~> 5.0"

# HTTP client (fallback mode)
gem "http"

# Deploy
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "webmock"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
  gem "shoulda-matchers"
end
