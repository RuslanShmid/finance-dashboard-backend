# frozen_string_literal: true

module Mutations
  module Users
    class SignUp < Mutations::BaseMutation
      description "Sign up a new user"

      argument :email, String, required: true
      argument :password, String, required: true
      argument :password_confirmation, String, required: true
      argument :first_name, String, required: false
      argument :last_name, String, required: false

      field :user, Types::UserType, null: true
      field :token, String, null: true
      field :errors, [ String ], null: false

      def resolve(email:, password:, password_confirmation:, first_name: nil, last_name: nil)
        user = User.new(
          email: email,
          password: password,
          password_confirmation: password_confirmation,
          first_name: first_name,
          last_name: last_name
        )

        if user.save
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
            errors: user.errors.full_messages
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

        JWT.encode(payload, secret)
      end
    end
  end
end
