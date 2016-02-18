class ArticlesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index, format: :json
    assert_response :success

    body = JSON.parse(response.body)

    assert_not_nil assigns(:articles)
  end

  test "should filter articles by author" do
    get :index, format: :json
  end

  test "should filter articles by tag" do
    get :index, format: :json
  end
end
