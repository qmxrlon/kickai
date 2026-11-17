Rails.application.routes.draw do
  # ── Auth ────────────────────────────────────────────────────────────────────
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions:      "users/sessions"
  }

  # ── Payment engine & webhooks ────────────────────────────────────────────────
  mount Pay::Engine, at: "/pay"

  # ── Sidekiq Web UI (admin only) ──────────────────────────────────────────────
  if defined?(Sidekiq)
    require "sidekiq/web"
    require "sidekiq-scheduler/web"
    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/admin/sidekiq"
    end
  end

  # ── Root ─────────────────────────────────────────────────────────────────────
  root "dashboard#index"

  # ── Public / subscriber pages ────────────────────────────────────────────────
  resources :matches, only: %i[index show] do
    member do
      get :prediction
    end
  end

  resources :predictions, only: %i[show]

  resources :subscriptions, only: %i[index create destroy] do
    collection do
      get  :success
      get  :cancel
      post :portal      # Stripe billing portal redirect
    end
  end

  get "pricing", to: "subscriptions#index", as: :pricing

  # ── Admin namespace ───────────────────────────────────────────────────────────
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :matches, only: %i[index show destroy] do
      member do
        post :trigger_prediction
      end
    end
    resources :users, only: %i[index show edit update destroy]
    resources :leagues, except: %i[show]
  end

  # ── Health check ─────────────────────────────────────────────────────────────
  get "up", to: proc { [200, {}, ["OK"]] }
end
