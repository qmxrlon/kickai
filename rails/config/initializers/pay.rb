Pay.setup do |config|
  config.business_name = "KickAI"
  config.business_address = ""
  config.application_name = "KickAI"
  config.support_email = ENV.fetch("SUPPORT_EMAIL", "support@kickai.app")

  config.default_product_name = "KickAI Subscription"

  config.automount_routes = false
  config.routes_path = "/pay"

  # Send email on charge/refund
  config.send_emails = true

  # Enabled payment processors
  config.enabled_processors = [:stripe]
  config.enabled_processors << :paypal if ENV["PAYPAL_CLIENT_ID"].present?
end

# Stripe configuration
if ENV["STRIPE_SECRET_KEY"].present?
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  Stripe.api_version = "2024-04-10"
end
