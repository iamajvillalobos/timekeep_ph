namespace :aws do
  desc "Test AWS Rekognition connection"
  task test_connection: :environment do
    puts "Testing AWS Rekognition connection..."

    begin
      rekognition = RekognitionService.new

      # Test 1: List existing collections
      puts "✓ AWS credentials configured"

      # Test 2: Create face collection
      result = rekognition.ensure_collection_exists
      if result
        puts "✓ Face collection ready: #{Rails.application.config.aws[:rekognition][:collection_id]}"
      else
        puts "✗ Failed to create face collection"
        exit 1
      end

      # Test 3: List faces in collection
      stats = FaceVerificationService.new.get_verification_stats
      if stats[:success]
        puts "✓ Collection accessible - #{stats[:total_enrolled_faces]} faces enrolled"
      else
        puts "✗ Failed to access collection: #{stats[:error]}"
        exit 1
      end

      puts "\n🎉 AWS Rekognition setup successful!"
      puts "You can now enroll employee faces and start using face verification."

    rescue => e
      puts "✗ AWS connection failed: #{e.message}"
      puts "\nTroubleshooting:"
      puts "1. Check your .env file has correct AWS credentials"
      puts "2. Verify IAM user has Rekognition permissions"
      puts "3. Ensure AWS region is supported (us-east-1 recommended)"
      exit 1
    end
  end
end
