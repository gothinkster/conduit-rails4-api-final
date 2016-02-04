class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :find_post!

  def index
    render json: { comments: @post.comments.order(created_at: :desc) }
  end

  def create
    comment = @post.comments.new(comment_params)
    comment.user = current_user

    if comment.save
      render json: { comments: @post.comments.order(created_at: :desc) }
    else
      render json: { errors: @comment.errors }
    end
  end

  private

  def find_post!
    @post = Post.find_by_slug!(parmas[:post_slug])
  end
end
