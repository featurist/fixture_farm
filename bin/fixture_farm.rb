#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/fixture_farm/fixture_recorder'

def usage
  puts 'Usage: bundle exec fixture_farm <record|status|stop> [fixture_name_prefix]'
  exit 1
end

case ARGV[0]
when 'record'
  FixtureFarm::FixtureRecorder.start_recording_session!(ARGV[1])
  puts "Recording fixtures#{" with prefix #{ARGV[1]}" unless ARGV[1].nil?}"
when 'status'
  puts "Recording is #{FixtureFarm::FixtureRecorder.recording_session_in_progress? ? 'on' : 'off'}"
when 'stop'
  FixtureFarm::FixtureRecorder.stop_recording_session!
  puts 'Stopped recording'
else
  usage
end
