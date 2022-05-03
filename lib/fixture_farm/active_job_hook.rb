# frozen_string_literal: true

require 'fixture_farm/hook'

module FixtureFarm
  module ActiveJobHook
    extend ActiveSupport::Concern
    include Hook

    included do
      around_perform :record_new_fixtures, if: :record_new_fixtures?
    end
  end
end
