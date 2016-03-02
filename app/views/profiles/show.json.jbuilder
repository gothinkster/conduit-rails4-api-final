json.profile do |json|
  json.(@user, :username, :bio, :image)
  json.following signed_in? ? current_user.following?(@user) : false
end
