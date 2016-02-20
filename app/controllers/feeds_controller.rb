class FeedsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @articles = current_user.feed_articles
  end
end
