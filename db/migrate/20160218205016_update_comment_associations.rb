class UpdateCommentAssociations < ActiveRecord::Migration
  def change
    remove_column :comments, :post_id, :integer
    add_reference :comments, :article, index: true
    add_reference :comments, :user, index: true
  end
end
