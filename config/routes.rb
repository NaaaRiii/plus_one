Rails.application.routes.draw do
  root                              "static_pages#home"
  get     "/signup",            to: "users#new"
  get     "/login",             to: "sessions#new"
  post    "/login",             to: "sessions#create"
  get     "/dashboard",         to: "dashboards#index"
  delete  "/logout",            to: "sessions#destroy"
  post    "/guest_login",       to: "guest_sessions#create"
  #put '/goals/:id/complete', to: 'goals#complete', as: 'complete_goal'
  put     "/dashboard",         to: "dashboards#index"

  resources :goals do
    member do
      put :complete
    end
    resources :small_goals do
      member do
        put :complete
      end
      resources :tasks
    end
  end
  namespace :api do
    namespace :v1 do
      resources :users, only: [:show]
    end
  end
  resources :users
  resources :account_activations, only: [:edit]
end