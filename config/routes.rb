Rails.application.routes.draw do
  # Health checks
  get "health", to: "health#index"
  get "health/redis", to: "health#redis_stats"
  
  # Investment flow routes
  root "investments#index"
  resources :investments, only: [:index, :new, :create, :show, :update]
  
  # Platform-specific investment routes
  resources :platforms, only: [:index] do
    resources :investments, only: [:new, :create]
  end
end
