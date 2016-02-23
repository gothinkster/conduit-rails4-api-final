class AddCounterCacheArticleFavorites < ActiveRecord::Migration
  def change
    add_column :articles, :favorites_count, :integer
  end
end
