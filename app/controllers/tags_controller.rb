class TagsController < ApplicationController
  def index
    render json: {tags: Post.tag_counts.order(taggings_count: :desc).map(&:name)}
  end

  def show
    render json: {posts: Post.includes(:user).tagged_with(params[:name])}
  end
end
