class User < ApplicationRecord
  has_many :activities, dependent: :destroy
  has_many :goals, class_name: 'Goal', dependent: :destroy
  has_many :small_goals, through: :goals, dependent: :destroy
  has_many :tasks, through: :small_goals, dependent: :destroy
  has_many :roulette_texts, dependent: :destroy

  after_create :create_default_roulette_texts

  attr_accessor :remember_token, :activation_token

  validates :tickets, numericality: { greater_than_or_equal_to: 0 }

  before_save   :downcase_email
  before_create :create_activation_digest
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # JWTトークンを生成するメソッド
  def generate_auth_token
    payload = { user_id: id }
    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end
  
  # 渡された文字列のハッシュ値を返す
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続的セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
    remember_digest
  end

  # セッションハイジャック防止のためにセッショントークンを返す
  # この記憶ダイジェストを再利用しているのは単に利便性のため
  def session_token
    remember_digest || remember
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # ユーザーの総合計経験値を計算する
  def add_exp(amount)
    self.total_exp += amount
    save
  end

  # ランクアップに必要な経験値を計算するメソッド
  def calculate_rank_up_experience(max_rank = 121)
    experiences = [0, 5]
    increment = 10

    (3..max_rank).each do |rank|
      increment += 5 if ((rank - 2) % 5).zero?
      experiences << experiences.last + increment
    end

    experiences
  end

  # ランクを計算するメソッド
  def calculate_rank
    total_exp = self.total_exp || 0.0
    experiences = calculate_rank_up_experience
  
    # ランク1の場合を特別に扱う
    return 1 if total_exp < experiences[1]
  
    experiences.each_with_index do |exp, index|
      return index if total_exp < exp
    end
  
    experiences.size
  end

  def update_rank
    with_lock do
      new_rank = calculate_rank
      next if (new_rank / 10) <= ((last_roulette_rank || 0) / 10)

      self.last_roulette_rank = new_rank
      save!
    end
  end

  def update_tickets
    with_lock do
      new_rank  = calculate_rank
      new_tens  = new_rank / 10
      old_tens  = (last_roulette_rank || 0) / 10
      inc_amount = new_tens - old_tens          # ★ ブロック内で定義
  
      return if inc_amount <= 0                 # 増分なしなら何もしない
  
      self.tickets            += inc_amount
      self.last_roulette_rank  = new_rank
      save!                                        # ← ここでコミット
  
      # ★ 参照もブロック内に置けば NameError は起きない
      Rails.logger.debug "Tickets +#{inc_amount} (rank #{last_roulette_rank})"
    end
  end

  # チケットを 1 枚消費。成功なら true, 枚数不足なら false を返す
  def use_ticket
    with_lock do                    # ① 同一レコードで行ロック
      return false unless tickets.positive?

      # decrement! は UPDATE users SET tickets = tickets - 1, updated_at = NOW() ...
      decrement!(:tickets)          # ② 成功時は true を返す
    end
    true
  rescue ActiveRecord::RecordInvalid
    false                           # validation に引っかかった場合も false
  end

  # アカウントを有効にする
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # プレイチケットを使う
  #def use_play_ticket
  #  if play_tickets.positive?
  #    decrement!(:play_tickets)
  #    true
  #  else
  #    false
  #  end
  #end

  # 編集チケットを使う
  #def use_edit_ticket
  #  if edit_tickets.positive?
  #    decrement!(:edit_tickets)
  #    true
  #  else
  #    false
  #  end
  #end

  protected

  def create_default_roulette_texts
    default_texts = {
      1 => "5分お散歩をする",
      2 => "お菓子を1つ食べる",
      3 => "3分間ストレッチをする",
      4 => "ジュースをコップ1杯飲む",
      5 => "好きな動物の写真や動画を5分観る",
      6 => "好きな曲を2曲聴く",
      7 => "好きな本を4ページ読む",
      8 => "5分間お昼寝をする",
      9 => "深いことは考えずに3枚適当に写真を撮る",
      10 => "5分間日記を書く",
      11 => "コーヒーor紅茶or緑茶を飲む",
      12 => "5分間瞑想をする"
    }
  
    default_texts.each do |number, text|
      roulette_texts.create(number: number, text: text) unless roulette_texts.exists?(number: number)
    end
  end

  private

  # メールアドレスをすべて小文字にする
  def downcase_email
    self.email = email.downcase
  end

  # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end