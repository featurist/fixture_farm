# frozen_string_literal: true

require 'fixture_farm/fixture_recorder'

module FixtureFarm
  module Hook
    def record_new_fixtures(&block)
      fixture_recorder = FixtureRecorder.resume_recording_session
      return unless fixture_recorder # Bail if session was stopped due to error

      begin
        fixture_recorder.record_new_fixtures { block.call }
      ensure
        fixture_recorder.update_recording_session
      end
    end

    private

    def record_new_fixtures?
      FixtureRecorder.recording_session_in_progress?
    end
  end
end
