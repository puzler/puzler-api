# The one true "is this board correct?" check, shared by the normal solve path
# (SubmitSolution) and competition grading so the two can never drift. Accepts
# the client cell_state shape ({ "r0c0" => 5 } or { "r0c0" => { "value" => 5 } }).
module SolutionGrader
  def self.correct?(puzzle, cell_state)
    submitted = cell_state.transform_values { |v| v.is_a?(Hash) ? v["value"] : v }
                          .reject { |_, v| v.nil? }
    solution = puzzle.solution
    solution.present? && submitted == solution.transform_keys(&:to_s)
  end
end
