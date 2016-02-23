class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    current_user.update_attributes(user_params)
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :image)
  end
end
