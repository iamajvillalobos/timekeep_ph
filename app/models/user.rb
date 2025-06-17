class User < ApplicationRecord
  belongs_to :account

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  enum :role, { admin: 0, hr: 1, manager: 2 }

  validates :name, presence: true
  validates :role, presence: true
  validates :email, presence: true,
                   format: { with: Devise.email_regexp },
                   uniqueness: { scope: :account_id, case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  scope :for_account, ->(account) { where(account: account) }

  private

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
