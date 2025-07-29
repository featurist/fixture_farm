# frozen_string_literal: true

require 'fixture_farm/fixture_recorder'

module FixtureFarm
  module TestHelper
    def record_fixtures(fixture_name_prefix = nil, &block)
      FixtureRecorder.new(fixture_name_prefix).record_fixtures(&block)
    end
  end
end
