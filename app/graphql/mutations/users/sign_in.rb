# frozen_string_literal: true

module Mutations
  module Users
    class SignIn < Mutations::BaseMutation
      description "Sign in a user"

      argument :email, String, required: true
      argument :password, String, required: true

      field :user, Types::UserType, null: true
      field :token, String, null: true
      field :errors, [String], null: false

      def resolve(email:, password:)
        user = User.find_by(email: email)

        if user && user.valid_password?(password)
          # Generate JWT token using devise-jwt
          token = generate_jwt_token(user)
          
          {
            user: user,
            token: token,
            errors: []
          }
        else
          {
            user: nil,
            token: nil,
            errors: ["Invalid email or password"]
          }
        end
      end

      private

      def generate_jwt_token(user)
        # Use the same JWT configuration as Devise
        secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
        expiration = 1.day.from_now.to_i
        jti = SecureRandom.uuid
        
        payload = {
          sub: user.id,
          exp: expiration,
          jti: jti
        }
        
        token = JWT.encode(payload, secret)
        
        # Store jti in denylist (it will be active until expiration)
        # Note: This pre-creates the entry but it won't block the token until sign_out
        # The denylist check happens on verification
        
        token
      end
    end
  end
end

