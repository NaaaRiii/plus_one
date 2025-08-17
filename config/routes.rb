Rails.application.routes.draw do
  get "/api/health", to: proc {
    [200, {}, ["OK"]]
  }

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
    post 'guest_login', to: 'guest_sessions#create'
    get 'current_user', to: 'current_users#show'
    patch 'current_user', to: 'current_users#update'
    get 'weekly_exp', to: 'activities#weekly_exp'
    get 'daily_exp', to: 'activities#daily_exp'

    resources :current_users do
      member do
        post :update_rank
      end
    end

    resources :roulette_texts, param: :number, only: %i[index show create update destroy] do
      collection do
        get   :tickets
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

    get 'small_goals/:id', to: 'small_goals#show'
    put 'small_goals/:id', to: 'small_goals#update'
    delete 'small_goals/:id', to: 'small_goals#destroy'

    delete 'users/withdrawal', to: 'users#withdrawal'
    post 'users/restore', to: 'users#restore'
  end

  resources :users
  resources :account_activations, only: [:edit]
  resources :tasks, only: [:update]
end