# The one true "is this board correct?" check, shared by the normal solve path
# (SubmitSolution), manual checking (CheckSolution), and competition grading so
# the paths can never drift. Grades against the PUBLISHED VERSION's solution and
# accepts the client cell_state shape ({ "r0c0" => 5 } or { "r0c0" => { "value" => 5 } }).
module SolutionGrader
  SOLVED = "SOLVED".freeze
  CORRECT_SO_FAR = "CORRECT_SO_FAR".freeze
  INCORRECT = "INCORRECT".freeze

  def self.correct?(puzzle, cell_state)
    result(puzzle, cell_state) == SOLVED
  end

  # Coarse verdict that never reveals which cells are wrong. Coerces both sides
  # to integers so JSON strings and numbers compare equal, and ignores
  # zero-valued cells (permissive entry lets players type a literal 0).
  def self.result(puzzle, cell_state)
    solution = puzzle.published_version&.solution
    return INCORRECT if solution.blank?

    sol = solution.transform_keys(&:to_s).transform_values(&:to_i)
    submitted = cell_state.transform_values { |v| v.is_a?(Hash) ? v["value"] : v }
                          .reject { |_, v| v.nil? }
                          .transform_keys(&:to_s)
                          .transform_values(&:to_i)
                          .reject { |_, v| v.zero? }

    # A filled cell that disagrees with the solution (wrong digit, or a digit
    # where the solution is blank) makes the whole board incorrect.
    return INCORRECT unless submitted.all? { |k, v| sol[k] == v }

    sol.all? { |k, v| submitted[k] == v } ? SOLVED : CORRECT_SO_FAR
  end
end
