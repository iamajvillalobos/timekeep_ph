class Admin::FaceEnrollmentController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_manager
  before_action :set_employee, only: [ :show, :enroll, :destroy ]

  def index
    @employees = current_account.employees.includes(:branch)
    @enrolled_count = @employees.where.not(face_template_id: nil).count
    @total_count = @employees.count
  end

  def show
    @enrollment_status = @employee.face_template_id.present? ? "enrolled" : "not_enrolled"
  end

  def enroll
    selfie_data = params[:selfie_data]

    unless selfie_data.present?
      render json: { success: false, error: "No photo provided" }, status: :bad_request
      return
    end

    begin
      image_data = decode_selfie_data(selfie_data)
      face_service = FaceVerificationService.new

      result = face_service.enroll_employee_face(image_data, @employee.id.to_s)

      if result[:success]
        @employee.update!(face_template_id: result[:face_template_id])
        render json: {
          success: true,
          message: "Face enrolled successfully",
          confidence: result[:confidence]
        }
      else
        render json: {
          success: false,
          error: result[:error] || "Face enrollment failed"
        }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Face enrollment error: #{e.message}"
      render json: {
        success: false,
        error: "Enrollment failed. Please try again."
      }, status: :internal_server_error
    end
  end

  def destroy
    if @employee.face_template_id.present?
      face_service = FaceVerificationService.new
      result = face_service.unenroll_employee_face(@employee)

      if result[:success]
        redirect_to admin_face_enrollment_path(@employee), notice: "Face enrollment removed successfully"
      else
        redirect_to admin_face_enrollment_path(@employee), alert: "Failed to remove face enrollment"
      end
    else
      redirect_to admin_face_enrollment_path(@employee), alert: "Employee not enrolled"
    end
  end

  private

  def set_employee
    @employee = current_account.employees.find(params[:id])
  end

  def ensure_admin_or_manager
    unless current_user.admin? || current_user.manager?
      redirect_to root_path, alert: "Access denied"
    end
  end

  def decode_selfie_data(selfie_data)
    if selfie_data.start_with?("data:image")
      Base64.decode64(selfie_data.split(",")[1])
    else
      Base64.decode64(selfie_data)
    end
  end
end
