module Common
  module Services
    # Thin wrapper around the Cloudinary upload/delete API.
    # We use the REST API directly via Faraday instead of the cloudinary gem
    # to keep dependencies slim and stay explicit about what we're doing.
    class CloudinaryService
      BASE_URL = "https://api.cloudinary.com/v1_1"

      def self.config
        Rails.configuration.x.app
      end

      # Uploads a file (ActionDispatch::Http::UploadedFile or any IO) to Cloudinary.
      # Returns the secure HTTPS URL of the uploaded asset.
      def self.upload(file, folder: "avatars")
        cloud_name = config.cloudinary_cloud_name
        api_key    = config.cloudinary_api_key
        api_secret = config.cloudinary_api_secret

        timestamp  = Time.current.to_i
        params     = { timestamp: timestamp, folder: folder }
        signature  = generate_signature(params, api_secret)

        conn = Faraday.new(url: "#{BASE_URL}/#{cloud_name}") do |f|
          f.request :multipart
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end

        response = conn.post("/image/upload") do |req|
          req.body = {
            file:      Faraday::FilePart.new(file.tempfile, file.content_type, file.original_filename),
            api_key:   api_key,
            timestamp: timestamp,
            folder:    folder,
            signature: signature
          }
        end

        result = JSON.parse(response.body)

        if response.success?
          { url: result["secure_url"], public_id: result["public_id"] }
        else
          raise StandardError, result.dig("error", "message") || "Cloudinary upload failed"
        end
      end

      # Destroys an asset by its public_id.
      def self.destroy(public_id)
        cloud_name = config.cloudinary_cloud_name
        api_key    = config.cloudinary_api_key
        api_secret = config.cloudinary_api_secret

        timestamp = Time.current.to_i
        params    = { public_id: public_id, timestamp: timestamp }
        signature = generate_signature(params, api_secret)

        conn = Faraday.new(url: "#{BASE_URL}/#{cloud_name}")
        conn.post("/image/destroy") do |req|
          req.body = {
            public_id: public_id,
            api_key:   api_key,
            timestamp: timestamp,
            signature: signature
          }
        end
      end

      # Generates the HMAC-SHA1 signature Cloudinary requires for authenticated requests.
      def self.generate_signature(params, api_secret)
        sorted = params.sort.map { |k, v| "#{k}=#{v}" }.join("&")
        OpenSSL::HMAC.hexdigest("SHA1", api_secret, sorted)
      end
    end
  end
end
