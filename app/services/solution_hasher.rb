require "digest"

# Produces a SHA-256 hash of a puzzle solution for client-side comparison.
# The algorithm MUST match utils/solutionHash.ts in the frontend exactly.
#
# Canonical format: sorted cell keys joined as "r0c0:5,r0c1:3,..."
# Sorted lexicographically by key to guarantee determinism.
class SolutionHasher
  def self.hash(solution_grid)
    return nil if solution_grid.blank?

    canonical = solution_grid
      .transform_keys(&:to_s)
      .sort
      .map { |key, value| "#{key}:#{value}" }
      .join(",")

    Digest::SHA256.hexdigest(canonical)
  end
end
