json.posts @posts do |post|
  json.slug post.slug
  json.title post.title
  json.body post.body
  json.author post.user.username if post.user
end
