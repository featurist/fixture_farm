# frozen_string_literal: true

class InheritedModel < User
  validates :special_field, presence: true
end
