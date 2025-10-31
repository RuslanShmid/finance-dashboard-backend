# frozen_string_literal: true

module Mutations
  module Users
    class SignOut < Mutations::BaseMutation
      description "Sign out the current user"

      field :success, Boolean, null: false
      field :message, String, null: false
      field :errors, [String], null: false

      def resolve
        current_user = context[:current_user]
        token = context[:token]
        
        if current_user && token.present?
          # Extract jti from token and add to denylist
          jti = extract_jti_from_token(token)
          exp = extract_exp_from_token(token)
          
          if jti
            # Add token to denylist (create or update)
            JwtDenylist.find_or_create_by(jti: jti) do |denylist_entry|
              denylist_entry.exp = Time.at(exp)
            end
          end
          
          {
            success: true,
            message: "Logged out successfully.",
            errors: []
          }
        else
          {
            success: false,
            message: "Couldn't find an active session.",
            errors: ["Not authenticated"]
          }
        end
      end

      private

      def extract_jti_from_token(token)
        begin
          secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
          decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
          decoded[0]["jti"]
        rescue JWT::DecodeError
          nil
        end
      end

      def extract_exp_from_token(token)
        begin
          secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
          decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
          decoded[0]["exp"] || 1.day.from_now.to_i
        rescue JWT::DecodeError
          1.day.from_now.to_i
        end
      end
    end
  end
end

