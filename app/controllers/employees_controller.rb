class EmployeesController < ApplicationController
  skip_before_action :authenticate_user!

  def identification
    # Show employee ID and PIN form
  end

  def authenticate
    employee_id = params[:employee_id]&.strip&.upcase
    pin = params[:pin]&.strip

    if employee_id.blank? || pin.blank?
      flash[:error] = "Employee ID and PIN are required"
      redirect_to employee_login_path
      return
    end

    @employee = if Current.account
                  Employee.joins(:account)
                         .where(employee_id: employee_id, pin: pin)
                         .where(accounts: { subdomain: Current.account.subdomain })
                         .first
    else
                  # For testing without subdomain or when no tenant context
                  Employee.where(employee_id: employee_id, pin: pin).first
    end

    if @employee
      session[:employee_id] = @employee.id
      flash[:success] = "Welcome, #{@employee.name}!"
      redirect_to clock_in_path
    else
      flash[:error] = "Invalid Employee ID or PIN"
      redirect_to employee_login_path
    end
  end

  def logout
    session[:employee_id] = nil
    flash[:success] = "Logged out successfully"
    redirect_to employee_login_path
  end
end
