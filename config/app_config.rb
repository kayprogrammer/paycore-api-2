# The app config class reads from environment variables.
# anyway_config raises Anyway::Config::ConfigLoadError at boot
# if any required variable is missing.
#
# Copy .env.example to .env and fill in your values.
class AppConfig < Anyway::Config
  config_name :app

  attr_config(
    jwt_secret: nil,
    jwt_expiry_hours: 24,
    frontend_url: "http://localhost:5173",
    cloudinary_cloud_name: nil,
    cloudinary_api_key: nil,
    cloudinary_api_secret: nil
  )

  required :jwt_secret, :cloudinary_cloud_name, :cloudinary_api_key, :cloudinary_api_secret

  coerce_types jwt_expiry_hours: :integer
end
