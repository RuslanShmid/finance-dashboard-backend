class UserSerializer
  def initialize(user)
    @user = user
  end

  def serializable_hash
    {
      data: {
        id: @user.id.to_s,
        type: "user",
        attributes: {
          id: @user.id,
          email: @user.email,
          first_name: @user.first_name,
          last_name: @user.last_name,
          created_at: @user.created_at,
          updated_at: @user.updated_at
        }
      }
    }
  end
end
