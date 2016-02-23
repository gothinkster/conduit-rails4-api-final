class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :find_article!

  def index
    @comments = @article.comments.order(created_at: :desc)
  end

  def create
    @comment = @article.comments.new(comment_params)
    @comment.user = current_user

    render json: { errors: @comment.errors } unless @comment.save
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  def find_article!
    @article = Article.find_by_slug!(params[:article_slug])
  end
end
