# frozen_string_literal: true

module Subscriptions
  class BaseSubscription < GraphQL::Schema::Subscription
    object_class Types::Objects::BaseObject
    field_class Types::Fields::BaseField
    argument_class Types::Arguments::BaseArgument
  end
end
