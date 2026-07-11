module Mutations
  module Competitions
    # A competition submission: graded server-side on the spot, stored on the
    # run (one row per puzzle; resubmitting replaces it, so the LAST submission
    # is what gets scored). The response verdict follows the collection's
    # policy — nil under blind. Never touches puzzle_plays/record_solve!, which
    # would leak the verdict through solved checkmarks.
    class SubmitCompetitionEntry < Mutations::BaseMutation
      description "Submit a board for one puzzle in your active competition run"

      argument :cell_state, GraphQL::Types::JSON, required: true,
        description: "Final cell state keyed by cell coordinate"
      argument :collection_id, ID, required: true, description: "The competition collection"
      argument :puzzle_id, ID, required: true, description: "The puzzle being submitted"

      field :accepted, Boolean, null: false, description: "Whether the submission was recorded"
      field :correct, Boolean, null: true,
        description: "The verdict; always nil under the blind policy"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, puzzle_id:, cell_state:)
        require_auth!
        collection = Collection.find_by(id: collection_id)
        run = collection&.competition_runs&.find_by(user: current_user)
        return failure("You have no run on this competition") unless run
        return failure("Time is up — this run is over") unless run.active?

        entry = collection.puzzle_entries.find_by(entryable_id: puzzle_id)
        return failure("That puzzle is not part of this competition") if entry.nil? || !entry.released?

        record(run, entry, cell_state)
      end

      private

      def record(run, entry, cell_state)
        submission = run.submissions.find_or_initialize_by(puzzle_id: entry.entryable_id)
        if run.collection.policy_single? && submission.persisted?
          return failure("Already submitted — this competition allows one submission per puzzle")
        end

        correct = SolutionGrader.correct?(entry.entryable, cell_state)
        submission.wrong_attempts += 1 unless correct
        submission.assign_attributes(correct:, cell_state:, submitted_at: Time.current)
        submission.save!

        { accepted: true, correct: run.collection.policy_blind? ? nil : correct, errors: [] }
      end

      def failure(message)
        { accepted: false, correct: nil, errors: [ message ] }
      end
    end
  end
end
