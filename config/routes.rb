Rails.application.routes.draw do
  scope :api do
    devise_for :users

    resource :profiles, only: [:update]
    resources :profiles, param: :username, only: [:show] do
      resource :follow, only: [:create, :destroy]
    end
    resources :posts, param: :slug, only: [:index, :show, :create, :update, :destroy]
    resource :feed, only: [:show]
  end
end
