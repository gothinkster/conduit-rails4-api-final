class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :articles
  has_many :comments
  has_many :favorites
  has_many :favorite_articles, through: :favorites, source: :article

  acts_as_follower
  acts_as_followable

  validates :username, uniqueness: true, presence: true

  def generate_jwt
    JWT.encode({ id: self.id,
                 username: self.username,
                 exp: 60.days.from_now.to_i },
               Rails.application.secrets.jwt_secret)
  end

  def feed_articles
    Article.includes(:user).where(user: User.followed_by(self)).order(created_at: :desc)
  end
end
