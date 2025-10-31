# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL Mutations', type: :request do
  describe 'signUp mutation' do
    let(:query) do
      <<~GQL
        mutation SignUp($input: SignUpInput!) {
          signUp(input: $input) {
            user {
              id
              email
              firstName
              lastName
            }
            token
            errors
          }
        }
      GQL
    end

    context 'with valid parameters' do
      let(:variables) do
        {
          input: {
            email: 'newuser@example.com',
            password: 'password123',
            passwordConfirmation: 'password123',
            firstName: 'John',
            lastName: 'Doe'
          }
        }
      end

      it 'creates a new user' do
        expect do
          post '/graphql', params: { query: query, variables: variables }
        end.to change(User, :count).by(1)
      end

      it 'returns user data and token' do
        post '/graphql', params: { query: query, variables: variables }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signUp']

        expect(data['errors']).to be_empty
        expect(data['user']).to be_present
        expect(data['user']['email']).to eq('newuser@example.com')
        expect(data['user']['firstName']).to eq('John')
        expect(data['user']['lastName']).to eq('Doe')
        expect(data['token']).to be_present
        expect(data['user']['id']).to be_present
      end

      it 'returns a valid JWT token' do
        post '/graphql', params: { query: query, variables: variables }

        json_response = JSON.parse(response.body)
        token = json_response['data']['signUp']['token']

        expect(token).to be_present
        # Verify it's a valid JWT token
        secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
        decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
        expect(decoded).to be_present
        expect(decoded[0]['sub']).to be_present
      end
    end

    context 'with invalid parameters' do
      context 'when email already exists' do
        let!(:existing_user) { create(:user, email: 'existing@example.com') }
        let(:variables) do
          {
            input: {
              email: 'existing@example.com',
              password: 'password123',
              passwordConfirmation: 'password123',
              firstName: 'John',
              lastName: 'Doe'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end

      context 'when passwords do not match' do
        let(:variables) do
          {
            input: {
              email: 'mismatch@example.com',
              password: 'password123',
              passwordConfirmation: 'different_password',
              firstName: 'John',
              lastName: 'Doe'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end

      context 'when password is too short' do
        let(:variables) do
          {
            input: {
              email: 'shortpass@example.com',
              password: '123',
              passwordConfirmation: '123',
              firstName: 'John',
              lastName: 'Doe'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
        end
      end

      context 'when first_name is missing' do
        let(:variables) do
          {
            input: {
              email: 'nofirstname@example.com',
              password: 'password123',
              passwordConfirmation: 'password123',
              lastName: 'Doe'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end

      context 'when last_name is missing' do
        let(:variables) do
          {
            input: {
              email: 'nolastname@example.com',
              password: 'password123',
              passwordConfirmation: 'password123',
              firstName: 'John'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end

      context 'when both first_name and last_name are missing' do
        let(:variables) do
          {
            input: {
              email: 'noname@example.com',
              password: 'password123',
              passwordConfirmation: 'password123'
            }
          }
        end

        it 'does not create a new user' do
          expect do
            post '/graphql', params: { query: query, variables: variables }
          end.not_to change(User, :count)
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signUp']

          expect(data['errors']).not_to be_empty
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end
    end
  end

  describe 'signIn mutation' do
    let(:query) do
      <<~GQL
        mutation SignIn($input: SignInInput!) {
          signIn(input: $input) {
            user {
              id
              email
              firstName
              lastName
            }
            token
            errors
          }
        }
      GQL
    end

    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      let(:variables) do
        {
          input: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
      end

      it 'returns user data and token' do
        post '/graphql', params: { query: query, variables: variables }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signIn']

        expect(data['errors']).to be_empty
        expect(data['user']).to be_present
        expect(data['user']['email']).to eq('test@example.com')
        expect(data['token']).to be_present
      end

      it 'returns a valid JWT token' do
        post '/graphql', params: { query: query, variables: variables }

        json_response = JSON.parse(response.body)
        token = json_response['data']['signIn']['token']

        expect(token).to be_present
        # Verify it's a valid JWT token
        secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
        decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
        expect(decoded).to be_present
        expect(decoded[0]['sub'].to_i).to eq(user.id)
      end
    end

    context 'with invalid credentials' do
      context 'when email does not exist' do
        let(:variables) do
          {
            input: {
              email: 'nonexistent@example.com',
              password: 'password123'
            }
          }
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signIn']

          expect(data['errors']).to include('Invalid email or password')
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end

      context 'when password is incorrect' do
        let(:variables) do
          {
            input: {
              email: 'test@example.com',
              password: 'wrong_password'
            }
          }
        end

        it 'returns errors' do
          post '/graphql', params: { query: query, variables: variables }

          json_response = JSON.parse(response.body)
          data = json_response['data']['signIn']

          expect(data['errors']).to include('Invalid email or password')
          expect(data['user']).to be_nil
          expect(data['token']).to be_nil
        end
      end
    end
  end

  describe 'signOut mutation' do
    let(:query) do
      <<~GQL
        mutation {
          signOut(input: {}) {
            success
            message
            errors
          }
        }
      GQL
    end

    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid authentication' do
      let(:token) do
        # Generate token directly using the same method as sign_in mutation
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

      it 'signs out successfully' do
        post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{token}" }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signOut']

        expect(data['success']).to be true
        expect(data['message']).to eq('Logged out successfully.')
        expect(data['errors']).to be_empty
      end

      it 'adds token to denylist' do
        expect do
          post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{token}" }
        end.to change(JwtDenylist, :count).by(1)
      end

      it 'extracts jti from token and stores it' do
        post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{token}" }

        secret = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
        decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
        jti = decoded[0]['jti']

        expect(JwtDenylist.exists?(jti: jti)).to be true
      end
    end

    context 'without authentication' do
      it 'returns error when no token is provided' do
        post '/graphql', params: { query: query }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signOut']

        expect(data['success']).to be false
        expect(data['message']).to eq("Couldn't find an active session.")
        expect(data['errors']).to include('Not authenticated')
      end

      it 'does not add anything to denylist' do
        expect do
          post '/graphql', params: { query: query }
        end.not_to change(JwtDenylist, :count)
      end
    end

    context 'with invalid token' do
      let(:invalid_token) { 'invalid.token.here' }

      it 'returns error for invalid token' do
        post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{invalid_token}" }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signOut']

        expect(data['success']).to be false
        expect(data['message']).to eq("Couldn't find an active session.")
        expect(data['errors']).to include('Not authenticated')
      end
    end

    context 'when token is already in denylist' do
      let(:token) do
        # Generate token directly using the same method as sign_in mutation
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

      before do
        # Sign out once to add to denylist
        post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{token}" }
      end

      it 'allows signing out again (idempotent)' do
        post '/graphql', params: { query: query }, headers: { 'Authorization' => "Bearer #{token}" }

        json_response = JSON.parse(response.body)
        data = json_response['data']['signOut']

        # Should still succeed, but denylist entry already exists
        expect(data['success']).to be true
        expect(data['message']).to eq('Logged out successfully.')
      end
    end
  end
end
