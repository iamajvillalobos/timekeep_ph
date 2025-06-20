class ClockInController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_employee!
  before_action :load_employee_branches, only: [ :show ]

  def show
    # Show smart dashboard with state detection
    @clock_entry = ClockEntry.new
    @employee_state = detect_employee_state
    @todays_hours = calculate_todays_hours
    @pay_period_hours = calculate_pay_period_hours
    @recent_entries = current_employee.clock_entries.order(created_at: :desc).limit(5)
    @default_branch = @branches.first
    @requires_selfie = selfie_required?(@employee_state[:action])
  end

  def create
    @employee = current_employee

    # Get form parameters
    branch_id = params[:branch_id]
    entry_type = params[:entry_type]
    gps_latitude = params[:gps_latitude]
    gps_longitude = params[:gps_longitude]
    selfie_data = params[:selfie_data] # Base64 image data

    # Validate required parameters
    selfie_required = selfie_required?(entry_type)

    if branch_id.blank? || gps_latitude.blank? || gps_longitude.blank?
      error_message = "Branch and location are required"
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

    if selfie_required && selfie_data.blank?
      error_message = "Selfie is required for clock-in"
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

    # Perform face verification BEFORE creating clock entry if selfie is required
    verification_result = nil
    if selfie_required && selfie_data.present?
      # Check if employee has face enrollment
      unless @employee.face_template_id.present?
        error_message = "Face enrollment required. Please contact HR to enroll your face."
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

      # Perform face verification immediately
      image_data = decode_selfie_data(selfie_data)
      verification_service = FaceVerificationService.new
      verification_result = verification_service.verify_employee_face(image_data, @employee.id.to_s)

      unless verification_result[:success]
        error_message = "Face verification failed. Please ensure good lighting and try again."
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
    end

    # Create clock entry (only if verification passed or not required)
    @clock_entry = ClockEntry.new(
      employee: @employee,
      branch: branch,
      entry_type: entry_type,
      gps_latitude: gps_latitude.to_f,
      gps_longitude: gps_longitude.to_f,
      selfie_url: selfie_required ? store_selfie(selfie_data) : nil,
      synced: true,
      verification_status: selfie_required ? :verified : :bypassed,
      face_confidence: verification_result&.dig(:confidence)
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
            message: "Successfully clocked #{entry_type.tr('_', ' ')}! Welcome, #{@employee.name}.",
            verification_status: @clock_entry.verification_status,
            confidence: @clock_entry.face_confidence
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

  def detect_employee_state
    last_entry = current_employee.clock_entries.order(created_at: :desc).first

    return {
      state: :clocked_out,
      action: :clock_in,
      message: "Ready to start your day",
      button_text: "Clock In",
      button_color: "green"
    } unless last_entry

    case last_entry.entry_type
    when "clock_in"
      # Employee is currently working
      {
        state: :clocked_in,
        action: :break_start, # Primary action when working
        message: "You're currently working",
        button_text: "Start Break",
        button_color: "yellow",
        secondary_action: :clock_out,
        secondary_button_text: "Clock Out",
        secondary_button_color: "red",
        clocked_in_at: last_entry.created_at,
        working_duration: calculate_current_session_duration
      }
    when "break_start"
      # Employee is currently on break
      {
        state: :on_break,
        action: :break_end,
        message: "You're on break",
        button_text: "End Break",
        button_color: "green",
        break_started_at: last_entry.created_at,
        break_duration: Time.current - last_entry.created_at
      }
    when "break_end"
      # Employee returned from break, back to working
      {
        state: :clocked_in,
        action: :break_start,
        message: "Back to work",
        button_text: "Start Break",
        button_color: "yellow",
        secondary_action: :clock_out,
        secondary_button_text: "Clock Out",
        secondary_button_color: "red",
        working_duration: calculate_current_session_duration
      }
    when "clock_out"
      # Employee is clocked out
      {
        state: :clocked_out,
        action: :clock_in,
        message: "Ready to start your work",
        button_text: "Clock In",
        button_color: "green"
      }
    end
  end

  def calculate_todays_hours
    entries = current_employee.clock_entries.today.order(:created_at)
    return 0 unless entries.any?

    total_seconds = 0
    session_start = nil

    entries.each do |entry|
      case entry.entry_type
      when "clock_in", "break_end"
        # Starting work or returning from break
        session_start = entry.created_at
      when "break_start", "clock_out"
        # Starting break or ending work
        if session_start
          total_seconds += (entry.created_at - session_start)
          session_start = nil
        end
      end
    end

    # If currently working (not on break), add current session time
    if session_start && [ :clocked_in ].include?(@employee_state[:state])
      total_seconds += (Time.current - session_start)
    end

    total_seconds / 3600.0 # Convert to hours
  end

  def calculate_pay_period_hours
    # Simple pay period calculation (current month)
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month

    entries = current_employee.clock_entries
      .where(created_at: start_date..end_date)
      .order(:created_at)

    return 0 unless entries.any?

    total_seconds = 0
    session_start = nil

    entries.each do |entry|
      case entry.entry_type
      when "clock_in", "break_end"
        # Starting work or returning from break
        session_start = entry.created_at
      when "break_start", "clock_out"
        # Starting break or ending work
        if session_start
          total_seconds += (entry.created_at - session_start)
          session_start = nil
        end
      end
    end

    # If currently working (not on break), add current session time
    if session_start && [ :clocked_in ].include?(@employee_state[:state])
      total_seconds += (Time.current - session_start)
    end

    total_seconds / 3600.0 # Convert to hours
  end

  def calculate_current_session_duration
    # Calculate time worked in current session (excluding breaks)
    today_entries = current_employee.clock_entries.today.order(:created_at)
    return 0 unless today_entries.any?

    total_seconds = 0
    session_start = nil

    today_entries.each do |entry|
      case entry.entry_type
      when "clock_in", "break_end"
        session_start = entry.created_at
      when "break_start", "clock_out"
        if session_start
          total_seconds += (entry.created_at - session_start)
          session_start = nil
        end
      end
    end

    # If currently working (session_start is set), add current time
    if session_start
      total_seconds += (Time.current - session_start)
    end

    total_seconds
  end

  def selfie_required?(action_or_entry_type)
    # Selfie is required for clock_in and break_end (starting work or returning from break)
    %w[clock_in break_end].include?(action_or_entry_type.to_s)
  end

  def decode_selfie_data(selfie_data)
    # Remove data:image/jpeg;base64, prefix if present
    base64_data = selfie_data.sub(/^data:image\/[a-z]+;base64,/, "")
    Base64.decode64(base64_data)
  end
end
