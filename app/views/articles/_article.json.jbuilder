json.(article, :title, :slug, :body, :created_at, :updated_at, :tag_list, :description)
json.author article.user, partial: 'profiles/profile', as: :user
json.favorited signed_in? ? current_user.favorited?(article) : false
json.favorites_count article.favorites_count || 0
