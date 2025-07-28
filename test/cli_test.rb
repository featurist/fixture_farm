# frozen_string_literal: true

require 'English'
require 'test_helper'

class CLITest < ActiveSupport::TestCase
  test 'CLI shows usage when no arguments provided' do
    result = run_cli([])
    assert_match(/Usage: bundle exec fixture_farm/, result[:output])
    assert_equal 1, result[:exit_code]
  end

  test 'CLI shows usage when invalid command provided' do
    result = run_cli(['invalid'])
    assert_match(/Usage: bundle exec fixture_farm/, result[:output])
    assert_equal 1, result[:exit_code]
  end

  test 'CLI record command starts recording session without prefix' do
    result = run_cli(['record'])
    assert_match(/Recording fixtures$/, result[:output])
    assert_equal 0, result[:exit_code]
    assert FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end

  test 'CLI record command starts recording session with prefix' do
    result = run_cli(%w[record my_prefix])
    assert_match(/Recording fixtures with prefix my_prefix/, result[:output])
    assert_equal 0, result[:exit_code]
    assert FixtureFarm::FixtureRecorder.recording_session_in_progress?

    # Verify the prefix is stored
    data = JSON.parse(File.read(FixtureFarm::FixtureRecorder.store_path))
    assert_equal 'my_prefix', data['fixture_name_prefix']
  end

  test 'CLI status command shows off when not recording' do
    result = run_cli(['status'])
    assert_match(/Recording is off/, result[:output])
    assert_equal 0, result[:exit_code]
  end

  test 'CLI status command shows on when recording' do
    FixtureFarm::FixtureRecorder.start_recording_session!('test')

    result = run_cli(['status'])
    assert_match(/Recording is on/, result[:output])
    assert_equal 0, result[:exit_code]
  end

  test 'CLI stop command stops recording session' do
    FixtureFarm::FixtureRecorder.start_recording_session!('test')
    assert FixtureFarm::FixtureRecorder.recording_session_in_progress?

    result = run_cli(['stop'])
    assert_match(/Stopped recording/, result[:output])
    assert_equal 0, result[:exit_code]
    refute FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end

  test 'CLI record command overwrites existing session' do
    FixtureFarm::FixtureRecorder.start_recording_session!('old_prefix')

    result = run_cli(%w[record new_prefix])
    assert_match(/Recording fixtures with prefix new_prefix/, result[:output])
    assert_equal 0, result[:exit_code]

    # Verify new prefix overwrites old one
    data = JSON.parse(File.read(FixtureFarm::FixtureRecorder.store_path))
    assert_equal 'new_prefix', data['fixture_name_prefix']
  end

  test 'CLI usage function shows correct format' do
    # Test the usage function by providing invalid command
    result = run_cli(['help'])
    assert_match(/Usage: bundle exec fixture_farm <record\|status\|stop> \[fixture_name_prefix\]/, result[:output])
    assert_equal 1, result[:exit_code]
  end

  test 'CLI status command shows error when session has error field' do
    # Create session file with error
    File.write(FixtureFarm::FixtureRecorder.store_path, {
      fixture_name_prefix: 'test_prefix',
      new_models: [],
      error: 'database was externally modified/reset'
    }.to_json)

    result = run_cli(['status'])
    assert_match(%r{Recording is off \(database was externally modified/reset\)}, result[:output])
    assert_equal 0, result[:exit_code]
  end

  private

  def run_cli(args)
    command = "cd #{Rails.root} && bundle exec #{File.expand_path('../bin/fixture_farm', __dir__)} #{args.join(' ')}"
    output = `#{command} 2>&1`
    exit_code = $CHILD_STATUS.exitstatus
    { output: output, exit_code: exit_code }
  end
end
