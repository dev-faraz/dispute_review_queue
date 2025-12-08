require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users

  root 'disputes#index'
  mount Sidekiq::Web => '/sidekiq'

  namespace :webhooks do
    resources :disputes, only: [:create]
  end

  namespace :reports do
    get :daily_volume
    get :time_to_decision
  end

  resources :disputes do
    member do
      patch :attach_evidence
      patch :transition
      delete :remove_evidence
    end
  end
end
