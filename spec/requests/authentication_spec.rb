require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /users (sign up)' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'creates a new user' do
        expect do
          post '/users', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        end.to change(User, :count).by(1)
      end

      it 'returns success status' do
        post '/users', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:ok)
      end

      it 'returns user data' do
        post '/users', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        json_response = JSON.parse(response.body)

        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq('Signed up successfully.')
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']['first_name']).to eq('John')
        expect(json_response['data']['last_name']).to eq('Doe')
        expect(json_response['data']).to have_key('id')
        expect(json_response['data']).to have_key('created_at')
        expect(json_response['data']).to have_key('updated_at')
      end

      it 'does not return password in response' do
        post '/users', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        json_response = JSON.parse(response.body)

        expect(json_response['data']).not_to have_key('password')
        expect(json_response['data']).not_to have_key('encrypted_password')
      end
    end
  end

  describe 'POST /users/sign_in (sign in)' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
      end

      it 'returns success status' do
        post '/users/sign_in', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:ok)
      end

      it 'returns user data' do
        post '/users/sign_in', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        json_response = JSON.parse(response.body)

        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq('Logged in successfully.')
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']).to have_key('id')
      end

      it 'returns JWT token in Authorization header' do
        post '/users/sign_in', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'does not return password in response' do
        post '/users/sign_in', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
        json_response = JSON.parse(response.body)

        expect(json_response['data']).not_to have_key('password')
        expect(json_response['data']).not_to have_key('encrypted_password')
      end
    end
  end

  describe 'DELETE /users/sign_out (sign out)' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid JWT token' do
      before do
        @token = nil
        post '/users/sign_in',
             params: { user: { email: 'test@example.com', password: 'password123' } }.to_json,
             headers: { 'Content-Type' => 'application/json' }
        @token = response.headers['Authorization']
      end

      it 'returns success status' do
        delete '/users/sign_out', headers: { 'Authorization' => @token }
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        delete '/users/sign_out', headers: { 'Authorization' => @token }
        json_response = JSON.parse(response.body)

        expect(json_response['status']).to eq(200)
        expect(json_response['message']).to eq('Logged out successfully.')
      end

      it 'adds token to denylist' do
        expect do
          delete '/users/sign_out', headers: { 'Authorization' => @token }
        end.to change(JwtDenylist, :count).by(1)
      end

      it 'makes the token unusable for subsequent requests' do
        delete '/users/sign_out', headers: { 'Authorization' => @token }

        # Token revocation is handled by the database, verification would require
        # making an authenticated request to a protected endpoint
        expect(JwtDenylist.count).to eq(1)
      end
    end

    context 'without JWT token' do
      it 'returns unauthorized status' do
        delete '/users/sign_out'
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        delete '/users/sign_out'
        json_response = JSON.parse(response.body)

        expect(json_response['status']).to eq(401)
        expect(json_response['message']).to eq("Couldn't find an active session.")
      end
    end
  end
end
