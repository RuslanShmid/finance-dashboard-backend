require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'devise configuration' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes trackable' do
      expect(User.devise_modules).to include(:trackable)
    end

    it 'includes jwt_authenticatable' do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end

  describe 'valid user creation' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user.valid?).to be true
    end

    it 'saves a valid user' do
      user = build(:user)
      expect { user.save! }.to change(User, :count).by(1)
    end
  end
end
