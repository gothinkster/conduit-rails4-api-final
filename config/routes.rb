Rails.application.routes.draw do
  scope :api do
    devise_for :users

    resource :profiles, only: [:update]
    resources :profiles, param: :username, only: [:show] do
      resource :follow, only: [:create, :destroy]
    end
    resources :articles, param: :slug, only: [:index, :show, :create, :update, :destroy] do
      resources :comments, only: [:create, :index]
    end
    resource :feed, only: [:show]
    resources :tags, param: :name, only: [:index, :show]
  end
end
