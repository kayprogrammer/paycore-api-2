require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "PayCore API",
        version: "v1",
        description: "PayCore REST API documentation"
      },
      servers: [
        { url: "http://localhost:3000", description: "Development" }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id:                 { type: :string, format: :uuid },
              first_name:         { type: :string },
              last_name:          { type: :string },
              full_name:          { type: :string },
              email:              { type: :string },
              phone:              { type: :string, nullable: true },
              avatar_url:         { type: :string, nullable: true },
              bio:                { type: :string, nullable: true },
              dob:                { type: :string, format: :date, nullable: true },
              is_email_verified:  { type: :boolean },
              is_staff:           { type: :boolean },
              is_active:          { type: :boolean },
              biometrics_enabled: { type: :boolean },
              push_enabled:       { type: :boolean },
              in_app_enabled:     { type: :boolean },
              email_enabled:      { type: :boolean },
              created_at:         { type: :string, format: "date-time" }
            },
            required: %w[id first_name last_name email is_email_verified created_at]
          }
        }
      },
      paths: {}
    }
  }

  # Output format: yaml is human-readable and git-diff friendly
  config.openapi_format = :yaml
end
