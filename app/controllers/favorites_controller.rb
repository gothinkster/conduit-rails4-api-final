class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_article!

  def create
    current_user.favorite(@article)

    render json: { favorited: true }
  end

  def destroy
    current_user.unfavorite(@article)

    render json: { favorited: false }
  end

  private

  def find_article!
    @article = Article.find_by_slug!(params[:article_slug])
  end
end
