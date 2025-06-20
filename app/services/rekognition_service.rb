class RekognitionService
  def initialize
    @client = Aws::Rekognition::Client.new
    @collection_id = Rails.application.config.aws[:rekognition][:collection_id]
  end

  # Create face collection if it doesn't exist
  def ensure_collection_exists
    @client.describe_collection(collection_id: @collection_id)
    Rails.logger.info "Face collection '#{@collection_id}' already exists"
    true
  rescue Aws::Rekognition::Errors::ResourceNotFoundException
    Rails.logger.info "Creating face collection '#{@collection_id}'"
    @client.create_collection(collection_id: @collection_id)
    true
  rescue => e
    Rails.logger.error "Failed to ensure collection exists: #{e.message}"
    false
  end

  # Add employee face to collection
  def index_face(image_data, employee_id)
    ensure_collection_exists

    response = @client.index_faces({
      collection_id: @collection_id,
      image: { bytes: image_data },
      external_image_id: "employee_#{employee_id}",
      detection_attributes: [ "ALL" ],
      quality_filter: "AUTO"
    })

    if response.face_records.any?
      face_id = response.face_records.first.face.face_id
      Rails.logger.info "Indexed face for employee #{employee_id}: #{face_id}"
      { success: true, face_id: face_id, face_details: response.face_records.first.face_detail }
    else
      Rails.logger.warn "No face detected in image for employee #{employee_id}"
      { success: false, error: "No face detected in image" }
    end
  rescue => e
    Rails.logger.error "Failed to index face for employee #{employee_id}: #{e.message}"
    { success: false, error: e.message }
  end

  # Search for employee face in collection
  def search_face(image_data, threshold: 80.0)
    response = @client.search_faces_by_image({
      collection_id: @collection_id,
      image: { bytes: image_data },
      face_match_threshold: threshold,
      max_faces: 1
    })

    if response.face_matches.any?
      match = response.face_matches.first
      employee_id = match.face.external_image_id&.gsub("employee_", "")

      Rails.logger.info "Face match found: Employee #{employee_id} with #{match.similarity}% confidence"
      {
        success: true,
        employee_id: employee_id,
        confidence: match.similarity,
        face_id: match.face.face_id
      }
    else
      Rails.logger.warn "No face matches found above #{threshold}% threshold"
      { success: false, error: "No matching face found" }
    end
  rescue => e
    Rails.logger.error "Face search failed: #{e.message}"
    { success: false, error: e.message }
  end

  # Detect face liveness to prevent spoofing
  def detect_liveness(image_data)
    # Note: Face Liveness requires a separate API call and video stream
    # For now, we'll use basic face detection with quality checks
    response = @client.detect_faces({
      image: { bytes: image_data },
      attributes: [ "ALL" ]
    })

    if response.face_details.any?
      face = response.face_details.first

      # Check face quality indicators
      quality_score = calculate_quality_score(face)

      Rails.logger.info "Face liveness check: Quality score #{quality_score}%"
      {
        success: true,
        quality_score: quality_score,
        face_details: face,
        is_live: quality_score > 70 # Basic threshold
      }
    else
      Rails.logger.warn "No face detected for liveness check"
      { success: false, error: "No face detected" }
    end
  rescue => e
    Rails.logger.error "Liveness detection failed: #{e.message}"
    { success: false, error: e.message }
  end

  # Remove employee face from collection
  def delete_face(face_id)
    @client.delete_faces({
      collection_id: @collection_id,
      face_ids: [ face_id ]
    })

    Rails.logger.info "Deleted face #{face_id} from collection"
    { success: true }
  rescue => e
    Rails.logger.error "Failed to delete face #{face_id}: #{e.message}"
    { success: false, error: e.message }
  end

  # List all faces in collection
  def list_faces
    response = @client.list_faces(collection_id: @collection_id)
    Rails.logger.info "Found #{response.faces.count} faces in collection"
    { success: true, faces: response.faces }
  rescue => e
    Rails.logger.error "Failed to list faces: #{e.message}"
    { success: false, error: e.message }
  end

  private

  # Calculate a quality score based on face attributes
  def calculate_quality_score(face_details)
    score = 100

    # Reduce score for poor quality indicators
    score -= 20 if face_details.quality.brightness < 30 || face_details.quality.brightness > 90
    score -= 20 if face_details.quality.sharpness < 50
    score -= 15 if face_details.sunglasses.value
    score -= 10 if face_details.eyes_open.confidence < 90
    score -= 10 if face_details.mouth_open.value
    score -= 15 if face_details.pose.yaw.abs > 30 || face_details.pose.pitch.abs > 30

    [ score, 0 ].max # Ensure score doesn't go below 0
  end
end
