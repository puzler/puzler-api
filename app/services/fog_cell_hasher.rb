require "digest"

# Per-cell fog verification hashes: SHA256("salt:cellKey:digit") for every
# solution cell, keyed by the internal 0-indexed cell key ("r0c0" = top-left).
# The client hashes a placed digit the same way and compares, so fog can clear
# on correct digits without the raw solution ever reaching the frontend.
#
# The algorithm MUST match fogCellHash in app/src/utils/fog.ts exactly. The
# salt is the version's solution_hash: public, stable per version, and it
# keeps identical grids from producing identical cell hashes across puzzles.
class FogCellHasher
  def self.hashes(solution_grid, salt)
    return nil if solution_grid.blank? || salt.blank?

    solution_grid
      .transform_keys(&:to_s)
      .to_h { |key, digit| [ key, Digest::SHA256.hexdigest("#{salt}:#{key}:#{digit}") ] }
  end
end
