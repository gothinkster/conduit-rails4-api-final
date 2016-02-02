class ProfilesController < ApplicationController
  before_filter :authenticate_user!, except: [:show]

  def show
    @user = User.find_by_username!(params[:username])
  end

  def update
    current_user.update_attributes(user_params)
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :image)
  end
end
