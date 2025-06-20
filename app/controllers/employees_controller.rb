class EmployeesController < ApplicationController
  skip_before_action :authenticate_user!

  def identification
    # Show employee ID and PIN form
  end

  def authenticate
    pin = params[:pin]&.strip

    if pin.blank?
      flash[:error] = "PIN is required"
      redirect_to employee_login_path
      return
    end

    @employee = if Current.account
                  Employee.joins(:account)
                         .where(pin: pin)
                         .where(accounts: { subdomain: Current.account.subdomain })
                         .first
    else
                  # For testing without subdomain or when no tenant context
                  Employee.where(pin: pin).first
    end

    if @employee
      session[:employee_id] = @employee.id
      flash[:success] = "Welcome, #{@employee.name}!"
      redirect_to clock_in_path
    else
      flash[:error] = "Invalid PIN"
      redirect_to employee_login_path
    end
  end

  def logout
    session[:employee_id] = nil
    flash[:success] = "Logged out successfully"
    redirect_to employee_login_path
  end
end
