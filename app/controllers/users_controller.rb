class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    unless current_user.update_attributes(user_params)
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :image)
  end
end
