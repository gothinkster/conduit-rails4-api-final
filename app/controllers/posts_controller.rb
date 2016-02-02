class PostsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]

  def index
    @posts = Post.all.includes(:user)

    @posts = @posts.tagged_with(params[:tag]) if params[:tag].present?
    @posts = @posts.where(user: User.where(username: params[:author])) if params[:author].present?

    @posts = @posts.order(created_at: :desc)
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user

    unless @post.save
      render json: { errors: @post.errors }, status: :unprocessable_entity
    end
  end

  def show
    @post = Post.find_by_slug!(params[:slug])
  end

  def update
    post = Post.find_by_slug!(params[:slug])
    post.update_attributes(post_params)
  end

  def destroy
    post = Post.find_by_slug!(params[:slug])
    post.destroy
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, tag_list: [])
  end
end
