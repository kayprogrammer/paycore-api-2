module Api
  module V1
    module Accounts
      class ProfilesController < ApplicationController
        before_action :authenticate_user!

        # GET /api/v1/accounts/profiles/
        # Returns the full profile of the currently authenticated user.
        def show
          render_success(data: { user: ::Accounts::Schemas::UserSchema.call(current_user) })
        end

        # PATCH /api/v1/accounts/profiles/
        # Updates editable profile fields. Email and password are changed via auth endpoints.
        def update
          if current_user.update(profile_params)
            render_success(
              data: { user: ::Accounts::Schemas::UserSchema.call(current_user) },
              message: "Profile updated successfully"
            )
          else
            render_error(
              message: "Profile update failed",
              errors: current_user.errors.full_messages,
              status: :unprocessable_entity
            )
          end
        end

        # POST /api/v1/accounts/profiles/avatar
        # Uploads a new avatar to Cloudinary and stores the URL on the user.
        def upload_avatar
          unless params[:avatar]&.respond_to?(:tempfile)
            return render_error(message: "No image file provided", status: :bad_request)
          end

          # Delete the old avatar from Cloudinary if it exists
          delete_existing_avatar

          result = Common::Services::CloudinaryService.upload(
            params[:avatar],
            folder: "paycore/avatars"
          )

          current_user.update!(avatar: result[:url])
          render_success(
            data: { avatar_url: current_user.avatar_url },
            message: "Avatar uploaded successfully"
          )
        rescue StandardError => e
          render_error(message: e.message, status: :unprocessable_entity)
        end

        # DELETE /api/v1/accounts/profiles/avatar
        # Removes the avatar from Cloudinary and clears it from the user record.
        def remove_avatar
          if current_user.avatar.blank? && current_user.social_avatar.blank?
            return render_error(message: "No avatar to remove", status: :bad_request)
          end

          delete_existing_avatar
          current_user.update!(avatar: nil)

          render_success(message: "Avatar removed successfully")
        end

        private

        def profile_params
          params.permit(:first_name, :last_name, :phone, :bio, :dob)
        end

        # Extracts the Cloudinary public_id from the stored URL and destroys the asset.
        # Cloudinary URLs follow: https://res.cloudinary.com/<cloud>/<type>/upload/<public_id>.<ext>
        def delete_existing_avatar
          return if current_user.avatar.blank?

          public_id = extract_cloudinary_public_id(current_user.avatar)
          Common::Services::CloudinaryService.destroy(public_id) if public_id
        end

        def extract_cloudinary_public_id(url)
          return nil unless url.to_s.include?("cloudinary.com")
          # Extract everything after /upload/ and strip the file extension
          match = url.match(%r{/upload/(?:v\d+/)?(.+?)(?:\.\w+)?$})
          match&.[](1)
        end
      end
    end
  end
end
