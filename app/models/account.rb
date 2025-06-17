class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :branches, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :clock_entries, through: :employees
  
  normalizes :subdomain, with: -> subdomain { subdomain.strip.downcase }
  normalizes :name, with: -> name { name.strip }
  
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  
  scope :active, -> { where(active: true) }
end
