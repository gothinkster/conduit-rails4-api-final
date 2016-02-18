json.(user, :id, :email, :created_at, :updated_at, :username, :bio, :image)
json.token user.generate_jwt
