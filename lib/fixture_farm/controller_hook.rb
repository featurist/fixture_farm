# frozen_string_literal: true

require 'fixture_farm/hook'

module FixtureFarm
  module ControllerHook
    extend ActiveSupport::Concern
    include Hook

    included do
      around_action :record_fixtures, if: :record_fixtures?
    end
  end
end
