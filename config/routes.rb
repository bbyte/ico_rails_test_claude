Rails.application.routes.draw do
  devise_for :users, path: "api/v1/users", path_names: {
    sign_in: "sign_in",
    sign_out: "sign_out"
  }, controllers: {
    sessions: "api/v1/sessions"
  }

  namespace :api do
    namespace :v1 do
      resources :feeds, only: [ :create ]
      resources :feed_items, only: [ :index ]
      get "health", to: "health#show"
    end
  end

  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check

  # Catch-all — serve React SPA for all other routes
  get "*path", to: "application#index", constraints: ->(req) {
    !req.xhr? && req.format.html?
  }
  root to: "application#index"
end
