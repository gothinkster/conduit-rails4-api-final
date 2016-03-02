Rails.application.routes.draw do
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }

    resource :user, only: [:show, :update]

    resources :profiles, param: :username, only: [:show] do
      resource :follow, only: [:create, :destroy]
    end

    resources :articles, param: :slug, except: [:edit, :new] do
      resources :comments, only: [:create, :index, :destroy]
      resource :favorite, only: [:create, :destroy]
    end

    resource :feed, only: [:show]
  end
end
