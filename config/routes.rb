Rails.application.routes.draw do
  scope :api, defaults: {format: :json}  do
    devise_for :users, controllers: { sessions: :sessions }

    resource :user, only: [:show, :update]
    resource :profiles, only: [:update]
    resources :profiles, param: :username, only: [:show] do
      resource :follow, only: [:create, :destroy]
    end
    resources :articles, param: :slug, only: [:index, :show, :create, :update, :destroy] do
      resources :comments, only: [:create, :index]
      resource :favorite, only: [:create, :destroy]
    end
    resource :feed, only: [:show]
    resources :tags, param: :name, only: [:index, :show]
  end
end
