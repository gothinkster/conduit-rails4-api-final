class FeedsController < ApplicationController
  before_filter :authenticate_user!

  def show
    posts = Post.all.includes(:user).where(user: User.followed_by(current_user)).order(created_at: :desc)

    render json: { posts: posts }
  end
end
