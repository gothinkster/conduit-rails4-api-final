class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts
  has_many :comments

  acts_as_follower
  acts_as_followable

  validates :username, uniqueness: true, presence: true

  def generate_jwt
    JWT.encode({ id: self.id,
                 exp: 60.days.from_now.to_i },
               Rails.application.secrets.jwt_secret)
  end
end
