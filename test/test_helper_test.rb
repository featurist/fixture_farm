# frozen_string_literal: true

require 'test_helper'

class TestHelperTest < ActiveSupport::TestCase
  include FixtureFarm::TestHelper

  test 'record_fixtures creates fixtures without prefix' do
    record_fixtures do
      User.create!(name: 'Helper User', email: 'helper@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('user_1')
    assert_equal 'Helper User', fixtures['user_1']['name']
  end

  test 'record_fixtures creates fixtures with prefix' do
    record_fixtures('helper_test') do
      User.create!(name: 'Prefixed User', email: 'prefixed@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('helper_test_user_1')
    assert_equal 'Prefixed User', fixtures['helper_test_user_1']['name']
  end

  test 'record_fixtures allows early stopping' do
    record_fixtures('early_stop') do |recorder|
      User.create!(name: 'First User', email: 'first@example.com')
      recorder.stop!
      User.create!(name: 'Second User', email: 'second@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('early_stop_user_1')
    assert_equal 'First User', fixtures['early_stop_user_1']['name']
    refute fixtures.key?('early_stop_user_2')
  end

  test 'record_fixtures works with hash argument for name replacement' do
    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert_not_includes fixtures.keys, 'new_user'

    record_fixtures(new_user: :user_1) do
      User.create!(name: 'Client User', email: 'client@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert_includes fixtures.keys, 'new_user'
  end
end
