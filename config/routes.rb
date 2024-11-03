Rails.application.routes.draw do
  #root                              "static_pages#home"
  #get     "/signup",            to: "users#new"
  #get     "/login",             to: "sessions#new"
  #post    "/login",             to: "sessions#create"
  #get     "/dashboard",         to: "dashboards#index"
  #delete  "/logout",            to: "sessions#destroy"
  #post    "/guest_login",       to: "guest_sessions#create"
  #put '/goals/:id/complete', to: 'goals#complete', as: 'complete_goal'
  #put     "/dashboard",         to: "dashboards#index"
  #get "roulette_texts/:number", to: "roulette_texts#show"
  #post "users/update_rank", to: "users#update_rank"
  #get "/users/tickets", to: "users#tickets"

  #get '/api/weekly_exp', to: 'activities#weekly_exp' 教訓
  #get '/api/daily_exp',  to: 'activities#daily_exp' 教訓

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
    get 'check_login', to: 'authentication#check_login'
    get 'weekly_exp', to: 'activities#weekly_exp'
    get 'daily_exp', to: 'activities#daily_exp'
    #get 'today_exp', to: 'activities#today_exp'

    resources :current_users do
      member do
        post :update_rank
      end
    end

    resources :roulette_texts, param: :number do
      collection do
        get :tickets
        patch :spin
      end
    end

    resources :goals do
      member do
        post :complete
      end
      resources :small_goals do
        member do
          post :complete
        end
      end
    end

    resources :tasks, only: [] do
      member do
        post :complete, to: 'tasks#update_completed'
      end
    end

    # 個別の small_goal に対する独立したアクセスパス（/api/small_goals/:id など）は通常不要。
    # small_goals に直接アクセスする場合（ネストされた親リソース（goal）を経由しない場合）は、そのようなルーティングが必要。
    get 'small_goals/:id', to: 'small_goals#show'
    put 'small_goals/:id', to: 'small_goals#update'
    delete 'small_goals/:id', to: 'small_goals#destroy'
  end

  resources :users
  resources :account_activations, only: [:edit]
  resources :tasks, only: [:update]
end