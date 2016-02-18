class ArticlesControllerTest < ActionController::TestCase
  test 'index should return array' do
    get :index, format: :json
    assert_response :success

    body = JSON.parse(response.body)

    assert_not_nil assigns(:articles)
    assert_not_nil body['articles']
    assert body['articles'].is_a? Array
  end

  test 'index should filter articles by author' do
    get :index, format: :json, author: 'jake'

    assert_response :success

    body = JSON.parse(response.body)
    article = body['articles'].first

    assert_equal article['author']['username'], 'jake'
  end

  test 'index should filter articles by tag' do
    get :index, format: :json, tag: 'rails'

    assert_response :success

    body = JSON.parse(response.body)
    article = body['articles'].first

    assert article['tagList'].include?('rails')
  end

  test 'show should find article by slug' do
    get :show, format: :json, slug: 'how-to-train-your-dragon'

    assert_response :success

    body = JSON.parse(response.body)
    article = body['article']

    assert_not_nil assigns(:article)
    assert_equal article['slug'], 'how-to-train-your-dragon'
  end

  test 'create should create article' do
    title = 'How to NOT train your dragon'

    user = User.first

    @request.headers['Authorization'] = 'Token ' + user.generate_jwt

    post :create, article: { title: title,
                             description: 'Ever wonder how?',
                             body: 'You have to believe' },
                  format: :json

    assert_response :success

    body = JSON.parse(response.body)
    article = body['article']

    assert_not_nil assigns(:article)
    assert_equal article['slug'], title.parameterize
    assert_equal article['author']['username'], user.username
  end

  test 'update article with authenticated user' do
    article = Article.first
    user = article.user

    new_title = 'new title'

    @request.headers['Authorization'] = 'Token ' + user.generate_jwt

    put :update, format: :json, article: { title: new_title }, slug: article.slug

    assert_response :success

    body = JSON.parse(response.body)
    article_json = body['article']

    assert_not_nil assigns(:article)
    assert_equal article_json['slug'], new_title.parameterize
  end

  test 'update article with wrong user' do
    article = Article.first
    user = User.create(email: 'john@jacob.com', username: 'johnnyjake', password: 'password')

    new_title = 'new title'

    @request.headers['Authorization'] = 'Token ' + user.generate_jwt

    put :update, format: :json, article: { title: new_title }, slug: article.slug

    assert_response :forbidden
  end
end
