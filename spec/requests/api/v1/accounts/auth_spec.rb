require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  path "/api/v1/accounts/auth/register" do
    post "Register a new user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          first_name:            { type: :string, example: "Kay" },
          last_name:             { type: :string, example: "Programmer" },
          email:                 { type: :string, example: "kay@example.com" },
          password:              { type: :string, example: "secret123" },
          password_confirmation: { type: :string, example: "secret123" }
        },
        required: %w[first_name last_name email password password_confirmation]
      }

      response "201", "User registered successfully" do
        let(:body) { { first_name: "Kay", last_name: "Test", email: "newuser@example.com", password: "secret123", password_confirmation: "secret123" } }
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     user:  { "$ref" => "#/components/schemas/User" },
                     token: { type: :string }
                   }
                 }
               }
        run_test!
      end

      response "422", "Validation failed" do
        let(:body) { { first_name: "", last_name: "", email: "bad", password: "x", password_confirmation: "y" } }
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string },
                 errors:  { type: :array, items: { type: :string } }
               }
        run_test!
      end
    end
  end

  path "/api/v1/accounts/auth/login" do
    post "Log in an existing user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          email:    { type: :string, example: "kay@example.com" },
          password: { type: :string, example: "secret123" }
        },
        required: %w[email password]
      }

      response "200", "Logged in successfully" do
        let!(:user) { Accounts::Models::User.create!(first_name: "Kay", last_name: "Test", email: "login@example.com", password: "secret123", password_confirmation: "secret123") }
        let(:body)  { { email: "login@example.com", password: "secret123" } }
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     user:  { "$ref" => "#/components/schemas/User" },
                     token: { type: :string }
                   }
                 }
               }
        run_test!
      end

      response "401", "Invalid credentials" do
        let!(:user) { Accounts::Models::User.create!(first_name: "Kay", last_name: "Test", email: "login2@example.com", password: "secret123", password_confirmation: "secret123") }
        let(:body)  { { email: "login2@example.com", password: "wrongpassword" } }
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Invalid credentials" }
               }
        run_test!
      end
    end
  end

  path "/api/v1/accounts/auth/me" do
    get "Get the current authenticated user" do
      tags "Auth"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "Current user returned" do
        let!(:user)         { Accounts::Models::User.create!(first_name: "Kay", last_name: "Test", email: "me@example.com", password: "secret123", password_confirmation: "secret123") }
        let(:Authorization) { "Bearer #{Common::Utils::JwtService.encode(user_id: user.id)}" }
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     user: { "$ref" => "#/components/schemas/User" }
                   }
                 }
               }
        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        schema type: :object,
               properties: {
                 success: { type: :boolean, example: false },
                 message: { type: :string, example: "Unauthorized" }
               }
        run_test!
      end
    end
  end
end
