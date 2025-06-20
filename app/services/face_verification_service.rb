class FaceVerificationService
  def initialize
    @rekognition = RekognitionService.new
  end

  # Verify employee face during clock-in
  def verify_employee_face(image_data, expected_employee_id)
    Rails.logger.info "Starting face verification for employee #{expected_employee_id}"

    # Step 1: Check face liveness/quality
    liveness_result = @rekognition.detect_liveness(image_data)
    unless liveness_result[:success]
      return {
        success: false,
        error: "Face detection failed: #{liveness_result[:error]}",
        step: "liveness_check"
      }
    end

    unless liveness_result[:is_live]
      return {
        success: false,
        error: "Image quality too low (score: #{liveness_result[:quality_score]}%)",
        step: "quality_check"
      }
    end

    # Step 2: Search for matching face in collection
    search_result = @rekognition.search_face(image_data, threshold: 75.0)
    unless search_result[:success]
      return {
        success: false,
        error: "No matching face found in system",
        step: "face_search"
      }
    end

    # Step 3: Verify the matched employee is the expected one
    matched_employee_id = search_result[:employee_id]
    if matched_employee_id != expected_employee_id
      Rails.logger.warn "Face mismatch: Expected #{expected_employee_id}, got #{matched_employee_id}"
      return {
        success: false,
        error: "Face verification failed - identity mismatch",
        step: "identity_verification",
        matched_employee_id: matched_employee_id
      }
    end

    # Step 4: Check confidence level
    confidence = search_result[:confidence]
    if confidence < 85.0
      return {
        success: false,
        error: "Face verification confidence too low (#{confidence.round(1)}%)",
        step: "confidence_check",
        confidence: confidence
      }
    end

    Rails.logger.info "Face verification successful for employee #{expected_employee_id} with #{confidence.round(1)}% confidence"

    {
      success: true,
      employee_id: expected_employee_id,
      confidence: confidence,
      quality_score: liveness_result[:quality_score],
      face_id: search_result[:face_id]
    }
  end

  # Enroll new employee face
  def enroll_employee_face(image_data, employee_id)
    Rails.logger.info "Enrolling face for employee #{employee_id}"

    # Step 1: Check face quality
    liveness_result = @rekognition.detect_liveness(image_data)
    unless liveness_result[:success]
      return {
        success: false,
        error: "Face detection failed: #{liveness_result[:error]}",
        step: "face_detection"
      }
    end

    unless liveness_result[:quality_score] > 80
      return {
        success: false,
        error: "Image quality too low for enrollment (score: #{liveness_result[:quality_score]}%)",
        step: "quality_check",
        quality_score: liveness_result[:quality_score]
      }
    end

    # Step 2: Index the face
    index_result = @rekognition.index_face(image_data, employee_id)
    unless index_result[:success]
      return {
        success: false,
        error: "Failed to enroll face: #{index_result[:error]}",
        step: "face_indexing"
      }
    end

    Rails.logger.info "Successfully enrolled face for employee #{employee_id}"

    {
      success: true,
      employee_id: employee_id,
      face_id: index_result[:face_id],
      face_template_id: index_result[:face_id], # AWS Rekognition uses face_id as template identifier
      quality_score: liveness_result[:quality_score]
    }
  end

  # Remove employee from face collection
  def unenroll_employee_face(employee)
    return { success: true, message: "No face enrolled" } unless employee.face_template_id

    delete_result = @rekognition.delete_face(employee.face_template_id)
    if delete_result[:success]
      employee.update(face_template_id: nil)
      Rails.logger.info "Unenrolled face for employee #{employee.id}"
      { success: true, message: "Face successfully removed" }
    else
      { success: false, error: delete_result[:error] }
    end
  end

  # Check if employee has enrolled face
  def employee_has_enrolled_face?(employee)
    employee.face_template_id.present?
  end

  # Get verification statistics
  def get_verification_stats
    list_result = @rekognition.list_faces
    if list_result[:success]
      {
        success: true,
        total_enrolled_faces: list_result[:faces].count,
        collection_id: Rails.application.config.aws[:rekognition][:collection_id]
      }
    else
      { success: false, error: list_result[:error] }
    end
  end

  # Handle verification failure with fallback options
  def handle_verification_failure(clock_entry, verification_result)
    Rails.logger.warn "Face verification failed for clock entry #{clock_entry.id}: #{verification_result[:error]}"

    # Determine fallback strategy based on failure reason
    case verification_result[:step]
    when "liveness_check"
      # Poor photo quality - allow bypass but flag for admin review
      clock_entry.update!(
        verification_status: :bypassed,
        face_confidence: 0.0
      )
      {
        success: true,
        bypassed: true,
        reason: "Photo quality too low",
        action: "Entry allowed with admin review flagged"
      }

    when "face_search"
      # Employee not enrolled - allow but suggest enrollment
      clock_entry.update!(
        verification_status: :bypassed,
        face_confidence: 0.0
      )
      {
        success: true,
        bypassed: true,
        reason: "Employee face not enrolled",
        action: "Entry allowed - enrollment recommended"
      }

    when "identity_mismatch", "confidence_check"
      # Potential security issue - require admin approval
      clock_entry.update!(
        verification_status: :failed,
        face_confidence: verification_result[:confidence] || 0.0
      )
      {
        success: false,
        blocked: true,
        reason: "Face verification failed",
        action: "Entry blocked - admin approval required"
      }

    else
      # Unknown error - allow with admin review
      clock_entry.update!(
        verification_status: :bypassed,
        face_confidence: 0.0
      )
      {
        success: true,
        bypassed: true,
        reason: "Verification system error",
        action: "Entry allowed with admin review flagged"
      }
    end
  end
end
