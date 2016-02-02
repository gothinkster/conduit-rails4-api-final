class AddImageAndBioToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bio, :text
    add_column :users, :image, :string
  end
end
