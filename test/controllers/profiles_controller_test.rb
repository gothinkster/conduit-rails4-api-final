class ProfilesControllerTest < ActionController::TestCase
  test 'show should return profile' do
    username = User.first.username

    get :show, format: :json, username: username

    assert_response :success

    profile = JSON.parse(response.body)['profile']

    assert_equal profile['username'], username
  end

  test 'update should update profile' do
    user = User.first
    token = user.generate_jwt
    new_email = 'drizzy@drake.com'

    @request.headers['Authorization'] = 'Token ' + token

    put :update, format: :json, user: { email: new_email }

    assert_response :success

    profile = JSON.parse(response.body)['user']

    assert_equal profile['email'], new_email
  end
end
