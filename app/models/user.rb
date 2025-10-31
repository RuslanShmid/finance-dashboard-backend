class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, confirmation: true, length: { minimum: 6, maximum: 20 }
  validates :password_confirmation, presence: true
end
