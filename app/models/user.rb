class User < ApplicationRecord
  #before_save { self.email = email.downcase }
  before_save { email.downcase! }
  validates :name,  presence: true, length: { maximum: 50 }
  #VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                          format: { with: VALID_EMAIL_REGEX },
                          uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }

  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  has_many :goals, class_name: 'Goal', dependent: :destroy

  # 『update_columnsを使ってDBに保存するが、バリデーションは行わない』を試す
  def add_exp(points)
    new_exp = self.exp + points
    while new_exp >= current_rank_required_exp
      new_exp -= current_rank_required_exp
      self.rank += 1
    end
    update_columns(exp: new_exp, rank: self.rank)
  end
  

  def current_rank_required_exp
    self.rank * 5
  end
  
end
