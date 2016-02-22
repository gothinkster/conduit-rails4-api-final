class ArticlesController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]

  def index
    @articles = Article.all.includes(:user)

    @articles = @articles.tagged_with(params[:tag]) if params[:tag].present?
    @articles = @articles.where(user: User.where(username: params[:author])) if params[:author].present?

    @articles = @articles.order(created_at: :desc)
  end

  def create
    @article = Article.new(article_params)
    @article.user = current_user

    unless @article.save
      render json: { errors: @article.errors }, status: :unprocessable_entity
    end
  end

  def show
    @article = Article.find_by_slug!(params[:slug])
  end

  def update
    @article = Article.find_by_slug!(params[:slug])
    if @article.user_id == @current_user_id
      @article.update_attributes(article_params)
    else
      head :forbidden
    end
  end

  def destroy
    article = Article.find_by_slug!(params[:slug])
    article.destroy
  end

  private

  def article_params
    params.require(:article).permit(:title, :body, :description, tag_list: [])
  end
end
