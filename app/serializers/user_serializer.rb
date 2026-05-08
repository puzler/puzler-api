class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      id: @user.id,
      email: @user.email,
      username: @user.username,
      avatar_url: @user.avatar_url,
      bio: @user.bio,
      role: @user.role
    }
  end
end
