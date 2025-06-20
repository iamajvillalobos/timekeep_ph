class FaceVerificationJob < ApplicationJob
  queue_as :default

  def perform(clock_entry_id, selfie_data)
    clock_entry = ClockEntry.find(clock_entry_id)
    employee = clock_entry.employee

    Rails.logger.info "Processing face verification for clock entry #{clock_entry_id}"

    # Decode base64 selfie data
    image_data = decode_selfie_data(selfie_data)

    # Perform face verification
    verification_service = FaceVerificationService.new
    result = verification_service.verify_employee_face(image_data, employee.id.to_s)

    if result[:success]
      clock_entry.update!(
        verification_status: :verified,
        face_confidence: result[:confidence]
      )
      Rails.logger.info "Face verification successful for clock entry #{clock_entry_id}"
    else
      # Handle verification failure with fallback strategies
      fallback_result = verification_service.handle_verification_failure(clock_entry, result)
      Rails.logger.info "Fallback handling applied for clock entry #{clock_entry_id}: #{fallback_result[:reason]}"
    end

  rescue => e
    Rails.logger.error "Face verification job failed for clock entry #{clock_entry_id}: #{e.message}"
    clock_entry&.update(verification_status: :failed)
    raise e
  end

  private

  def decode_selfie_data(selfie_data)
    # Remove data:image/jpeg;base64, prefix if present
    base64_data = selfie_data.sub(/^data:image\/[a-z]+;base64,/, "")
    Base64.decode64(base64_data)
  end
end
