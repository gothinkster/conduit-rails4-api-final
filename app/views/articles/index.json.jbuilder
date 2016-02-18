json.articles do |json|
  json.array! @articles, partial: 'articles/article', as: :article
end
