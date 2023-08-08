# frozen_string_literal: true

module Fields
  class BaseField < GraphQL::Schema::Field
    argument_class Arguments::BaseArgument
  end
end
