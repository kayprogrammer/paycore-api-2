source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "pg", "~> 1.1"

# Async fiber-based web server (replaces Puma for true non-blocking I/O)
gem "falcon"

# Auth
gem "bcrypt", "~> 3.1.7"
gem "jwt", "~> 3.1"

# CORS
gem "rack-cors"

# Load .env files before Rails initializers (required for anyway_config to read env vars at boot)
gem "dotenv-rails", require: "dotenv/load"

# Typed, validated environment config (raises at boot if required vars are missing)
gem "anyway_config", "~> 2.6"

# Background jobs & caching (DB-backed, no Redis required)
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"

# Pagination
gem "pagy", "~> 9.3"

# Boot time optimization
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false
gem "thruster", require: false

gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
