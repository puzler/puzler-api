FactoryBot.define do
  factory :collection_entry do
    association :collection
    sequence(:position)

    # Specs mostly add puzzles; pass `puzzle:` (or any `entryable:`) explicitly.
    transient do
      puzzle { nil }
    end

    entryable { puzzle || association(:puzzle) }
  end
end
