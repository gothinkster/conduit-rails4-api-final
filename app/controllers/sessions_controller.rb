class SessionsController < Devise::SessionsController
  def create
    user = User.find_by_email(params[:user][:email])

    if user.valid_password?(params[:user][:password])
      @current_user = user
    else
      render json: { errors: { 'username or password' => 'is invalid' } }, status: :unprocessable_entity
    end
  end
end
