# frozen_string_literal: true

require 'test_helper'

class ActiveJobHookTest < ActiveSupport::TestCase
  class TestJob < ApplicationJob
    include FixtureFarm::ActiveJobHook

    def perform(rm_user: false)
      if rm_user
        User.find_by(email: 'job@example.com').destroy
      else
        User.create!(name: 'Job User', email: 'job@example.com')
      end
    end
  end

  test 'captures fixtures during job execution' do
    FixtureFarm::FixtureRecorder.start_recording_session!('job_capture')

    TestJob.perform_now

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('job_capture_user_1')
    assert_equal 'Job User', fixtures['job_capture_user_1']['name']
  end

  test 'does not capture when no recording session' do
    TestJob.perform_now

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    refute fixtures.key?('job_capture_user_1')
  end

  test 'updates recording session after second job execution' do
    skip 'TODO'

    FixtureFarm::FixtureRecorder.start_recording_session!('job_update')

    TestJob.perform_now

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('job_update_user_1')

    TestJob.perform_now(rm_user: true)

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    refute fixtures.key?('job_update_user_1')
  end
end
