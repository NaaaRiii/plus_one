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
  get "roulette_texts/:number", to: "roulette_texts#show"
  post "users/update_rank", to: "users#update_rank"
  get "/users/tickets", to: "users#tickets"

  get '/api/weekly_exp', to: 'activities#weekly_exp'
  get '/api/daily_exp',  to: 'activities#daily_exp'

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
    post 'login', to: 'authentication#login'
    get 'current_user', to: 'current_users#show'
    delete 'logout', to: 'sessions#destroy'
    resources :roulette_texts do
      collection do
        get :tickets
      end
    end
  end
  

  resources :users
  resources :account_activations, only: [:edit]
  resources :tasks, only: [:update]
  resources :roulette_texts
end