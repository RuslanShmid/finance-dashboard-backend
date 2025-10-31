class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
end
