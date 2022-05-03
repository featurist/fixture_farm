# frozen_string_literal: true

require 'fixture_farm/version'

module FixtureFarm
  autoload :ActiveRecordExtension, 'fixture_farm/active_record_extension'
  autoload :ControllerHook, 'fixture_farm/controller_hook'
  autoload :ActiveJobHook, 'fixture_farm/active_job_hook'
  autoload :TestHelper, 'fixture_farm/test_helper'
  autoload :FixtureRecorder, 'fixture_farm/fixture_recorder'
end

ActiveSupport.on_load(:active_record) do
  include FixtureFarm::ActiveRecordExtension
end
