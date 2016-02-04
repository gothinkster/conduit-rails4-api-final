json.post do
  json.slug @post.slug
  json.title @post.title
  json.body @post.body
  json.author @post.user if @post.user
  json.tag_list @post.tag_list
end
