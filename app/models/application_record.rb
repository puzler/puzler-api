# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  protected

  def validate_attribute(attribute, value: nil)
    self.errors.delete(attribute)

    self.class.validators_on(attribute).each do |validator|
      validator.validate_each(self, attribute, value || self.send(attribute))
    end

    self.errors[attribute].empty?
  end
end
