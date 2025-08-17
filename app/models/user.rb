class User < ApplicationRecord
  include Discard::Model
  self.discard_column = :deleted_at

  has_many :activities, dependent: :nullify
  has_many :goals, class_name: 'Goal', dependent: :nullify
  has_many :small_goals, through: :goals
  has_many :tasks, through: :small_goals
  has_many :roulette_texts, dependent: :nullify

  after_create :create_default_roulette_texts

  attr_accessor :remember_token

  validates :tickets, numericality: { greater_than_or_equal_to: 0 }

  before_save :downcase_email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true, on: :create

  def generate_auth_token
    payload = { user_id: id }
    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end
  
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
    remember_digest
  end

  def session_token
    remember_digest || remember
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def add_exp(amount)
    self.total_exp += amount
    save

    # EXP 加算に伴うチケット付与をここでも行う
    update_tickets
  end

  def calculate_rank_up_experience(max_rank = 121)
    experiences = [0, 5]
    increment = 10

    (3..max_rank).each do |rank|
      increment += 5 if ((rank - 2) % 5).zero?
      experiences << experiences.last + increment
    end

    experiences
  end

  def calculate_rank
    total_exp = self.total_exp || 0.0
    experiences = calculate_rank_up_experience
  
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
      inc_amount = new_tens - old_tens
  
      return if inc_amount <= 0
  
      self.tickets            += inc_amount
      self.last_roulette_rank  = new_rank
      save!
  
      Rails.logger.debug "Tickets +#{inc_amount} (rank #{last_roulette_rank})"
    end
  end

  def use_ticket
    with_lock do
      return false unless tickets.positive?

      decrement!(:tickets)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # データ喪失リスク対策：destroy メソッドを一時的に無効化
  def destroy
    raise ActiveRecord::RecordNotDestroyed.new("物理削除は禁止されています。論理削除を使用してください。", self)
  end

  def destroy!
    raise ActiveRecord::RecordNotDestroyed.new("物理削除は禁止されています。論理削除を使用してください。", self)
  end

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

  def downcase_email
    self.email = email.downcase
  end

end