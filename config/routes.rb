Rails.application.routes.draw do
  root                        "static_pages#home"
  get     "/signup",      to: "users#new"
  get     "/login",       to: "sessions#new"
  post    "/login",       to: "sessions#create"
  delete  "/logout",      to: "sessions#destroy"
  get     "/guest_login", to: "guest_sessions#create"
  #post    "/guest_login",  to: "guest_sessions#create"
  resources :users
  resources :account_activations, only: [:edit]
end
