# frozen_string_literal: true

module Schemas
  class PuzlerMutations < BaseObject
    implements Schemas::Auth::AuthMutations

    description 'The base Mutation Object'
  end
end
