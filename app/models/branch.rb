class Branch < ApplicationRecord
  belongs_to :account
  has_many :employees, dependent: :destroy
  has_many :clock_entries, dependent: :destroy

  normalizes :name, with: ->(name) { name.strip }
  normalizes :address, with: ->(address) { address.strip }

  validates :name, presence: true
  validates :address, presence: true

  scope :active, -> { where(active: true) }
  scope :for_account, ->(account) { where(account: account) }
end
