FactoryBot.define do
  factory :cosmetic do
    association :puzzle
    cosmetic_type { :cell_color }
    position { { "type" => "cell", "cells" => [ "r0c0" ] } }
    style { { "color" => "#ff0000", "opacity" => 0.5 } }
    data { {} }
    display_order { 0 }
  end
end
