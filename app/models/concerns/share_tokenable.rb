# Unguessable URL key for share links, minted on create. The token IS the
# secret that gates the unlisted/containers_only visibility tiers (see each
# model's viewable_by?), so it must stay high-entropy and never be exposed to
# viewers who only have container-level access.
module ShareTokenable
  extend ActiveSupport::Concern

  included do
    before_create :generate_share_token
  end

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
