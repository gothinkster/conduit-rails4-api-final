json.(article, :id, :title, :slug, :body, :created_at, :updated_at)
json.author article.user, partial: 'profiles/profile', as: :user
