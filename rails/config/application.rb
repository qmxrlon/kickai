require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module KickAI
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # Timezone (Germany)
    config.time_zone = "Berlin"
    config.active_record.default_timezone = :utc

    # Locale
    config.i18n.default_locale = :de
    config.i18n.available_locales = %i[de en]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # Background jobs via Sidekiq
    config.active_job.queue_adapter = :sidekiq

    # Generator defaults
    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec, fixture: false
      g.helper false
      g.assets false
      g.view_specs false
    end

    # Allow ActionController::Parameters to be used in jobs
    config.action_controller.permit_all_parameters = false
  end
end
