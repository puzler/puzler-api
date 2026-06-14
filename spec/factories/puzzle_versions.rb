FactoryBot.define do
  factory :puzzle_version do
    association :puzzle
    label { nil }
    definition do
      {
        "version" => 2,
        "activeConstraints" => [ { "type" => "thermometer" }, { "type" => "killer_cage" } ],
        "globals" => { "variants" => [ "diagonal_positive" ], "custom" => [] }
      }
    end
    solution { { "r0c0" => 5, "r0c1" => 3 } }

    after(:build) do |version|
      version.solution_hash = SolutionHasher.hash(version.solution) if version.solution.present?
      version.constraint_types = ConstraintTypeExtractor.extract(version.definition) if version.constraint_types.blank?
    end
  end
end
