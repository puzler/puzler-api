# Compiles everything we store about a user into a portable hash (GDPR
# Art. 20 data portability). Never include OAuth access/refresh tokens —
# they are credentials, not the user's data.
class UserDataExport
  def initialize(user)
    @user = user
  end

  def as_json
    {
      exported_at: Time.current.iso8601,
      profile: profile,
      oauth_connections: oauth_connections,
      puzzles: puzzles,
      puzzle_plays: puzzle_plays,
      ratings: ratings,
      comments: comments,
      favorites: favorites
    }
  end

  private

  attr_reader :user

  def profile
    user.slice(:id, :email, :username, :display_name, :bio, :role, :created_at).merge(
      avatar_url: user.resolved_avatar_url
    )
  end

  def oauth_connections
    user.oauth_identities.map { |i| i.slice(:provider, :uid, :created_at) }
  end

  def puzzles
    user.puzzles.includes(:versions).map do |puzzle|
      puzzle.as_json.merge(
        "versions" => puzzle.versions.as_json
      )
    end
  end

  def puzzle_plays
    user.puzzle_plays.as_json
  end

  def ratings
    user.ratings.as_json
  end

  def comments
    user.comments.as_json
  end

  def favorites
    user.favorites.map { |f| f.slice(:puzzle_id, :created_at) }
  end
end
