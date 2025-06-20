require "aws-sdk-rekognition"
require "aws-sdk-s3"

# Load AWS configuration
aws_config = Rails.application.config_for(:aws)

# Configure AWS SDK
Aws.config.update({
  region: aws_config[:region],
  credentials: Aws::Credentials.new(
    aws_config[:access_key_id],
    aws_config[:secret_access_key]
  )
})

# Make AWS config available throughout the app
Rails.application.config.aws = aws_config
