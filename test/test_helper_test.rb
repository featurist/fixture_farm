# frozen_string_literal: true

require 'test_helper'

class TestHelperTest < ActiveSupport::TestCase
  include FixtureFarm::TestHelper

  test 'record_new_fixtures creates fixtures without prefix' do
    record_new_fixtures do
      User.create!(name: 'Helper User', email: 'helper@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('user_1')
    assert_equal 'Helper User', fixtures['user_1']['name']
  end

  test 'record_new_fixtures creates fixtures with prefix' do
    record_new_fixtures('helper_test') do
      User.create!(name: 'Prefixed User', email: 'prefixed@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('helper_test_user_1')
    assert_equal 'Prefixed User', fixtures['helper_test_user_1']['name']
  end

  test 'record_new_fixtures allows early stopping' do
    record_new_fixtures('early_stop') do |stop_recording|
      User.create!(name: 'First User', email: 'first@example.com')
      stop_recording.call
      User.create!(name: 'Second User', email: 'second@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('early_stop_user_1')
    assert_equal 'First User', fixtures['early_stop_user_1']['name']
    refute fixtures.key?('early_stop_user_2')
  end
end
