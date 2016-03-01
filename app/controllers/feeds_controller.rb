class FeedsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @articles = current_user.feed_articles

    @articles_count = @articles.count

    @articles = @articles.offset(params[:skip] || 0).limit(params[:limit] || 20)
  end
end
