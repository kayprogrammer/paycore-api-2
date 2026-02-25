require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PaycoreApi2
  class Application < Rails::Application
    config.load_defaults 8.1

    # Autoload everything under app/modules as well as lib/
    config.autoload_paths << Rails.root.join("app/modules")
    config.eager_load_paths << Rails.root.join("app/modules")
    config.autoload_lib(ignore: %w[assets tasks])

    config.api_only = true

    # Use UUID as primary key type by default (requires pgcrypto extension)
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
