FactoryBot.define do
  factory :constraint do
    association :puzzle
    constraint_type { "killer_cage" }
    data { { "cells" => [ "r0c0", "r0c1" ], "sum" => 10 } }
    display_order { 0 }
  end
end
