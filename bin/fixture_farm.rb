#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/fixture_farm/fixture_recorder'

def usage
  puts 'Usage: bundle exec fixture_farm <record|status|stop> [name_prefix|name_prefix:replaces_name]'
  exit 1
end

case ARGV[0]
when 'record'
  prefix_arg = ARGV[1]

  # Parse hash syntax like "new_user:user_1" into {new_user: :user_1}
  if prefix_arg&.include?(':')
    parts = prefix_arg.split(':', 2)
    parsed_prefix = { parts[0].to_sym => parts[1].to_sym }
  else
    parsed_prefix = prefix_arg
  end

  FixtureFarm::FixtureRecorder.start_recording_session!(parsed_prefix)
  puts "Recording fixtures#{" with prefix #{prefix_arg}" unless prefix_arg.nil?}"
when 'status'
  if FixtureFarm::FixtureRecorder.recording_session_in_progress?
    puts 'Recording is on'
  elsif (error = FixtureFarm::FixtureRecorder.last_session_error)
    puts "Recording is off (#{error})"
  else
    puts 'Recording is off'
  end
when 'stop'
  FixtureFarm::FixtureRecorder.stop_recording_session!
  puts 'Stopped recording'
else
  usage
end
