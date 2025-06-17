class Employee < ApplicationRecord
  belongs_to :account
  belongs_to :branch
  has_many :clock_entries, dependent: :destroy

  normalizes :name, with: ->(name) { name.strip }
  normalizes :email, with: ->(email) { email&.strip&.downcase }
  normalizes :employee_id, with: ->(id) { id.strip.upcase }

  validates :name, presence: true
  validates :employee_id, presence: true, uniqueness: { scope: :account_id }
  validates :pin, presence: true, length: { minimum: 4 }

  scope :active, -> { where(active: true) }
  scope :for_account, ->(account) { where(account: account) }

  validate :branch_belongs_to_account

  private

  def branch_belongs_to_account
    return unless branch && account
    errors.add(:branch, "must belong to the same account") if branch.account != account
  end
end
