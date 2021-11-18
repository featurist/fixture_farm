# frozen_string_literal: true

require "fixture_farm/fixture_recorder"

module FixtureFarm
  module ControllerHook
    extend ActiveSupport::Concern

    included do
      around_action :record_new_fixtures, if: :record_new_fixtures?
    end

    private

    def record_new_fixtures(&block)
      fixture_recorder = FixtureRecorder.resume_recording_session

      fixture_recorder.record_new_fixtures do
        block.call
      end
    ensure
      fixture_recorder.update_recording_session
    end

    def record_new_fixtures?
      FixtureRecorder.recording_session_in_progress?
    end
  end
end
