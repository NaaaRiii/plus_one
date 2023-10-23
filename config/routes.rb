Rails.application.routes.draw do
  root                              "static_pages#home"
  get     "/signup",            to: "users#new"
  get     "/login",             to: "sessions#new"
  post    "/login",             to: "sessions#create"
  get     "/dashboard",         to: "dashboards#index"
  get     "/goals",             to: "goals#new"
  post    "/goals",             to: "goals#create"
  delete  "/logout",            to: "sessions#destroy"
  post    "/guest_login",       to: "guest_sessions#create"

  resources :goals do
    resources :small_goals do
      resources :tasks
    end
  end
  resources :users
  resources :account_activations, only: [:edit]
end
