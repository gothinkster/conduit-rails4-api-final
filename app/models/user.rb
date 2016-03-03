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

  validates :username, uniqueness: true, presence: true, allow_blank: false

  def generate_jwt
    JWT.encode({ id: self.id,
                 username: self.username,
                 exp: 60.days.from_now.to_i },
               Rails.application.secrets.jwt_secret)
  end

  def feed_articles
    Article.includes(:user).where(user: self.following_users).order(created_at: :desc)
  end

  def favorited?(article)
    favorites.find_by(article_id: article.id).present?
  end

  def favorite(article)
    favorites.find_or_create_by(article: article)
  end

  def unfavorite(article)
    favorites.where(article: article).destroy_all
  end
end
