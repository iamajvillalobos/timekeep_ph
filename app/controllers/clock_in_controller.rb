class ClockInController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_employee!
  before_action :load_employee_branches, only: [ :show ]

  def show
    # Show clock-in form with camera and GPS
    @clock_entry = ClockEntry.new
  end

  def create
    @employee = current_employee

    # Get form parameters
    branch_id = params[:branch_id]
    entry_type = params[:entry_type] || "clock_in"
    gps_latitude = params[:gps_latitude]
    gps_longitude = params[:gps_longitude]
    selfie_data = params[:selfie_data] # Base64 image data

    # Validate required parameters
    if branch_id.blank? || gps_latitude.blank? || gps_longitude.blank? || selfie_data.blank?
      error_message = "All fields are required: branch, location, and selfie"
      respond_to do |format|
        format.html {
          flash[:error] = error_message
          redirect_to clock_in_path
        }
        format.json {
          render json: { success: false, message: error_message }, status: :unprocessable_entity
        }
      end
      return
    end

    # Find the branch and validate it belongs to the employee's account
    branch = Branch.where(id: branch_id, account: @employee.account).first
    unless branch
      error_message = "Invalid branch selected"
      respond_to do |format|
        format.html {
          flash[:error] = error_message
          redirect_to clock_in_path
        }
        format.json {
          render json: { success: false, message: error_message }, status: :unprocessable_entity
        }
      end
      return
    end

    # Create clock entry
    @clock_entry = ClockEntry.new(
      employee: @employee,
      branch: branch,
      entry_type: entry_type,
      gps_latitude: gps_latitude.to_f,
      gps_longitude: gps_longitude.to_f,
      selfie_url: store_selfie(selfie_data),
      synced: true # Since we're online and saving directly
    )

    if @clock_entry.save
      respond_to do |format|
        format.html {
          flash[:success] = "Successfully clocked #{entry_type.tr('_', ' ')}! Welcome, #{@employee.name}."
          redirect_to clock_in_path
        }
        format.json {
          render json: {
            success: true,
            message: "Successfully clocked #{entry_type.tr('_', ' ')}! Welcome, #{@employee.name}."
          }
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = "Error recording clock entry: #{@clock_entry.errors.full_messages.join(', ')}"
          redirect_to clock_in_path
        }
        format.json {
          render json: {
            success: false,
            message: "Error recording clock entry: #{@clock_entry.errors.full_messages.join(', ')}"
          }, status: :unprocessable_entity
        }
      end
    end
  end

  private

  def authenticate_employee!
    unless session[:employee_id]
      respond_to do |format|
        format.html {
          flash[:error] = "Please log in first"
          redirect_to employee_login_path
        }
        format.json {
          render json: { success: false, message: "Please log in first" }, status: :unauthorized
        }
      end
      return
    end

    @current_employee = Employee.find_by(id: session[:employee_id])
    unless @current_employee
      session[:employee_id] = nil
      respond_to do |format|
        format.html {
          flash[:error] = "Invalid session. Please log in again."
          redirect_to employee_login_path
        }
        format.json {
          render json: { success: false, message: "Invalid session. Please log in again." }, status: :unauthorized
        }
      end
      nil
    end
  end

  def current_employee
    @current_employee
  end
  helper_method :current_employee

  def load_employee_branches
    # Load branches for the employee's account
    @branches = Branch.where(account: current_employee.account, active: true).order(:name)
  end

  def store_selfie(base64_data)
    # For now, we'll store a placeholder URL
    # In production, this would upload to cloud storage (S3, etc.)
    # and return the URL
    "placeholder_selfie_#{Time.current.to_i}.jpg"
  end
end
