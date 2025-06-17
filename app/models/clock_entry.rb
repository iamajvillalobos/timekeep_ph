class ClockEntry < ApplicationRecord
  belongs_to :employee
  belongs_to :branch

  enum :entry_type, { clock_in: 0, clock_out: 1 }

  validates :gps_latitude, presence: true, numericality: { in: -90..90 }
  validates :gps_longitude, presence: true, numericality: { in: -180..180 }
  validates :entry_type, presence: true

  scope :pending_sync, -> { where(synced: false) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :for_account, ->(account) { joins(employee: :account).where(employees: { account: account }) }

  validate :employee_and_branch_same_account

  private

  def employee_and_branch_same_account
    return unless employee && branch
    errors.add(:branch, "must belong to same account as employee") if employee.account != branch.account
  end
end
