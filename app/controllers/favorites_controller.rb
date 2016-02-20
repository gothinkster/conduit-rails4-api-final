class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_article!

  def create
    Favorite.find_or_create_by(user: current_user, article: @article)

    render json: { favorited: true }
  end

  def destroy
    Favorite.destroy_all(user: current_user, article: @article)

    render json: { favorited: false }
  end

  private

  def find_article!
    @article = Article.find_by_slug!(parmas[:article_slug])
  end
end
