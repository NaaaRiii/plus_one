Rails.application.routes.draw do
  root "static_pages#home"
  get "/signup", to: "users#new"
  #get 'users/new'
  #get 'static_pages/home'
end
