FactoryBot.define do
  factory :puzzle_version do
    association :puzzle
    label { nil }
    # v4-shaped definition. Deliberately gridless: several specs publish
    # factory versions without stubbing SudokuPad's createlink endpoint, and a
    # gridless definition keeps the link builder a no-op (UnsupportedGrid),
    # exactly as the old gridless v3 default did.
    definition do
      {
        "formatVersion" => 4,
        "constraints" => { "thermometers" => [], "killerCages" => [] },
        "globals" => { "diagonals" => { "positive" => true } }
      }
    end
    solution { { "r0c0" => 5, "r0c1" => 3 } }

    # The pre-v4 stored shape (activeConstraints + globals.variants), kept for
    # the extractor/encoder dual-format specs until B3 removes the v3 branch.
    trait :v3_definition do
      definition do
        {
          "version" => 2,
          "activeConstraints" => [ { "type" => "thermometer" }, { "type" => "killer_cage" } ],
          "globals" => { "variants" => [ "positive_diagonal" ], "custom" => [] }
        }
      end
    end

    after(:build) do |version|
      version.solution_hash = SolutionHasher.hash(version.solution) if version.solution.present?
      version.constraint_types = ConstraintTypeExtractor.extract(version.definition) if version.constraint_types.blank?
    end
  end
end
