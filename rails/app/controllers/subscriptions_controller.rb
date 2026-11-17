class SubscriptionsController < ApplicationController
  def index
    @plans = SubscriptionPlan.visible
  end

  def create
    @plan = SubscriptionPlan.find(params[:plan_id])

    if @plan.free?
      flash[:notice] = "Du bist bereits im kostenlosen Plan."
      redirect_to pricing_path and return
    end

    # Create/get the Pay customer and start checkout session
    processor = current_user.set_payment_processor(:stripe)

    begin
      checkout = processor.checkout(
        mode:       "subscription",
        line_items: [{ price: @plan.stripe_price_id, quantity: 1 }],
        success_url: success_subscriptions_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url:  cancel_subscriptions_url
      )
      redirect_to checkout.url, allow_other_host: true
    rescue Stripe::StripeError => e
      flash[:alert] = "Zahlung fehlgeschlagen: #{e.message}"
      redirect_to pricing_path
    end
  end

  def destroy
    current_user.payment_processor.cancel
    flash[:notice] = "Dein Abonnement wird zum Ende des aktuellen Zeitraums gekündigt."
    redirect_to pricing_path
  rescue StandardError => e
    flash[:alert] = "Kündigung fehlgeschlagen: #{e.message}"
    redirect_to pricing_path
  end

  def success
    flash[:notice] = "Willkommen bei KickAI Premium! Dein Abonnement ist jetzt aktiv."
    redirect_to root_path
  end

  def cancel
    flash[:alert] = "Zahlung abgebrochen."
    redirect_to pricing_path
  end

  def portal
    portal_session = current_user.payment_processor.billing_portal
    redirect_to portal_session.url, allow_other_host: true
  rescue StandardError
    flash[:alert] = "Kundenportal konnte nicht geöffnet werden."
    redirect_to pricing_path
  end
end
