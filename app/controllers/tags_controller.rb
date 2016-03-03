class TagsController < ApplicationController
  def index
    render json: { tags: Article.tag_counts.order(taggings_count: :desc).map(&:name) }
  end
end
