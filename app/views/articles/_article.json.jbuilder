json.(article, :title, :slug, :body, :created_at, :updated_at, :tag_list, :description, :favorites_count)
json.author article.user, partial: 'profiles/profile', as: :user
json.favorited signed_in? ? current_user.favorited?(article) : false
