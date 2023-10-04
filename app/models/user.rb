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

  has_many :goals       , dependent: :destroy
  has_many :small_goals , dependent: :destroy
  has_many :tasks       , dependent: :destroy

  # GPTの提案
  #def add_exp(points)
  #  self.exp += points
  #  while self.exp >= current_rank_required_exp
  #    self.exp -= current_rank_required_exp
  #    self.rank += 1
  #  end
  #  save!
  #end

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
    #(self.rank - 1) * 5
    self.rank * 5
  end
  
end
