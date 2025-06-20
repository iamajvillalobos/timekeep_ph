class HomeController < ApplicationController
  def index
    @account = current_account
    @setup_status = account_setup_status
    @branches = @account.branches.active.order(:name)
    @employees = @account.employees.active.includes(:branch).order(:name)
    @recent_clock_entries = @account.clock_entries.includes(:employee, :branch)
                                   .order(created_at: :desc).limit(10)
  end

  private

  def account_setup_status
    return @setup_status if defined?(@setup_status)

    @setup_status = {
      password_changed: password_changed?,
      branches_configured: branches_configured?,
      employees_added: employees_added?,
      clock_in_tested: clock_in_tested?,
      setup_complete: false
    }

    @setup_status[:setup_complete] = @setup_status.values.count(true) >= 3
    @setup_status
  end

  def password_changed?
    # Check if user's password was updated after account creation
    # Assuming temporary passwords are changed within first login session
    current_user.updated_at > current_user.created_at + 1.minute
  end

  def branches_configured?
    # Check if default branch address has been updated from placeholder
    @account.branches.active.where.not(address: "Please update this address").exists?
  end

  def employees_added?
    # Check if any employees have been added
    @account.employees.active.exists?
  end

  def clock_in_tested?
    # Check if any clock entries exist (indicates system has been tested)
    @account.clock_entries.exists?
  end
end
