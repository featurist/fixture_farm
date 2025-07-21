# frozen_string_literal: true

require 'test_helper'

class FixtureRecorderTest < ActiveSupport::TestCase
  test 'generates correct fixture names with prefix' do
    recorder = FixtureFarm::FixtureRecorder.new('my_prefix')

    recorder.record_new_fixtures do
      User.create!(name: 'Test User', email: 'test@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('my_prefix_user_1')

    assert_equal 'Test User', fixtures['my_prefix_user_1']['name']
  end

  test 'generates correct fixture names without prefix' do
    recorder = FixtureFarm::FixtureRecorder.new(nil)
    recorder.record_new_fixtures do
      User.create!(name: 'Test User', email: 'test@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('user_1')

    assert_equal 'Test User', fixtures['user_1']['name']
  end

  test 'recording_session_in_progress? returns correct status' do
    refute FixtureFarm::FixtureRecorder.recording_session_in_progress?

    FixtureFarm::FixtureRecorder.start_recording_session!('test_prefix')
    assert FixtureFarm::FixtureRecorder.recording_session_in_progress?

    FixtureFarm::FixtureRecorder.stop_recording_session!
    refute FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end

  test 'resume_recording_session loads existing session' do
    user = User.create!(name: 'Test User', email: 'test@example.com')
    File.write(FixtureFarm::FixtureRecorder::STORE_PATH, {
      fixture_name_prefix: 'some_prefix',
      new_models: [['User', user.id]]
    }.to_json)

    recorder = FixtureFarm::FixtureRecorder.resume_recording_session

    recorder.record_new_fixtures {}

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('some_prefix_user_1')

    assert_equal 'Test User', fixtures['some_prefix_user_1']['name']
  end

  test 'record_new_fixtures allows early stopping' do
    recorder = FixtureFarm::FixtureRecorder.new(nil)

    recorder.record_new_fixtures do |stop_recording|
      User.create!(name: 'Test User', email: 'test@example.com')
      stop_recording.call
      User.create!(name: 'Test User 2', email: 'test2@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('user_1')

    assert_equal 'Test User', fixtures['user_1']['name']

    refute fixtures.key?('user_2') # Second user should not be recorded
  end

  test 'record_new_fixtures creates fixture files' do
    user_fixtures_file = Rails.root.join('test', 'fixtures', 'users.yml')
    FileUtils.rm(user_fixtures_file)

    FixtureFarm::FixtureRecorder.new(nil).record_new_fixtures do
      User.create!(name: 'Test User', email: 'test@example.com')
    end

    assert File.exist?(user_fixtures_file)
  end

  test 'record_new_fixtures handles associations properly' do
    recorder = FixtureFarm::FixtureRecorder.new('test')

    recorder.record_new_fixtures do
      user = User.create!(name: 'Test User', email: 'test@example.com')
      user.posts.create!(title: 'Test Post', content: 'Test content')
    end

    user_fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    post_fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'posts.yml'))

    assert user_fixtures.key?('test_user_1')
    assert post_fixtures.key?('test_user_1_post_1')
    assert_equal 'test_user_1', post_fixtures['test_user_1_post_1']['user']
  end

  test 'record_new_fixtures handles polymorphic associations' do
    recorder = FixtureFarm::FixtureRecorder.new('poly')

    recorder.record_new_fixtures do
      user = User.create!(name: 'Test User', email: 'test@example.com')
      Notification.create!(message: 'Test notification', notifiable: user)
    end

    user_fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    notification_fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'notifications.yml'))

    assert user_fixtures.key?('poly_user_1')
    assert notification_fixtures.key?('poly_user_1_notification_1')
    assert_equal 'poly_user_1', notification_fixtures['poly_user_1_notification_1']['notifiable']
  end

  test 'record_new_fixtures handles duplicate names' do
    FixtureFarm::FixtureRecorder.new(nil).record_new_fixtures do
      User.create!(name: 'Test User 1', email: 'test1@example.com')
      User.create!(name: 'Test User 2', email: 'test2@example.com')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    assert fixtures.key?('user_1')
    assert fixtures.key?('user_2')
  end

  test 'handles deleted models during reload' do
    recorder = FixtureFarm::FixtureRecorder.new('delete_test')

    user_to_delete = nil
    recorder.record_new_fixtures do |stop_recording|
      user_to_delete = User.create!(name: 'User to Delete', email: 'delete@example.com')
      User.create!(name: 'User to Keep', email: 'keep@example.com')

      # Delete the first user before recording ends
      user_to_delete.destroy!

      stop_recording.call
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))

    # Only the user that wasn't deleted should be in fixtures
    assert fixtures.key?('delete_test_user_1')
    assert_equal 'User to Keep', fixtures['delete_test_user_1']['name']

    # Should not have a second user fixture since first was deleted
    refute fixtures.key?('delete_test_user_2')
  end

  test 'handles low priority parent models for naming' do
    FixtureFarm.low_priority_parent_model_for_naming = ->(model) { model.is_a?(TenantModel) }

    recorder = FixtureFarm::FixtureRecorder.new('priority_test')

    recorder.record_new_fixtures do
      tenant = TenantModel.create!(name: 'Test Tenant')
      User.create!(name: 'Test User', email: 'test@example.com')

      # Create a model that belongs to both tenant and user
      # The user should take priority over tenant in naming
      TenantPost.create!(title: 'Test Post', tenant_model: tenant)
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'tenant_posts.yml'))

    # Should be named with tenant (low priority) since no high priority parent exists
    assert fixtures.key?('priority_test_tenant_model_1_tenant_post_1')
  ensure
    FixtureFarm.low_priority_parent_model_for_naming = nil
  end

  test 'serialize_attributes handles various data types' do
    recorder = FixtureFarm::FixtureRecorder.new('test')

    # Test TimeWithZone
    time = Time.zone.now
    result = recorder.send(:serialize_attributes, time)
    assert result.start_with?('<%=')
    assert result.end_with?('%>')

    # Test Date
    date = Date.today
    result = recorder.send(:serialize_attributes, date)
    assert result.start_with?('<%=')
    assert result.end_with?('%>')

    # Test BigDecimal
    decimal = BigDecimal('10.5')
    result = recorder.send(:serialize_attributes, decimal)
    assert_equal 10.5, result

    # Test Hash
    hash = { 'key' => 'value' }
    result = recorder.send(:serialize_attributes, hash)
    assert_equal '{"key":"value"}', result

    # Test Duration
    duration = 1.hour
    result = recorder.send(:serialize_attributes, duration)
    assert_equal 'PT1H', result

    # Test regular value
    string = 'test'
    result = recorder.send(:serialize_attributes, string)
    assert_equal 'test', result
  end

  test 'handles STI models correctly' do
    recorder = FixtureFarm::FixtureRecorder.new('sti_test')

    recorder.record_new_fixtures do
      InheritedModel.create!(name: 'Test Inherited', email: 'inherited@example.com', special_field: 'Special Value')
    end

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'inherited_models.yml'))

    assert fixtures.key?('sti_test_inherited_model_1')
    assert_equal 'Test Inherited', fixtures['sti_test_inherited_model_1']['name']
    assert_equal 'Special Value', fixtures['sti_test_inherited_model_1']['special_field']
  end

  test 'recording_session_in_progress? returns false when session has error field' do
    # Create session file with error
    File.write(FixtureFarm::FixtureRecorder::STORE_PATH, {
      fixture_name_prefix: 'test_prefix',
      new_models: [],
      error: 'database was externally modified/reset'
    }.to_json)

    refute FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end

  test 'recording_session_in_progress? returns true when session exists without error field' do
    File.write(FixtureFarm::FixtureRecorder::STORE_PATH, {
      fixture_name_prefix: 'test_prefix',
      new_models: []
    }.to_json)

    assert FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end

  test 'resume_recording_session handles missing records by adding error to session' do
    # Create session file with non-existent model ID
    File.write(FixtureFarm::FixtureRecorder::STORE_PATH, {
      fixture_name_prefix: 'test_prefix',
      new_models: [['User', 99_999]] # Non-existent ID
    }.to_json)

    # This should return nil and not raise an error
    recorder = FixtureFarm::FixtureRecorder.resume_recording_session
    assert_nil recorder

    # Check that session now contains error
    session_data = JSON.parse(File.read(FixtureFarm::FixtureRecorder::STORE_PATH))
    assert session_data['error']
    assert_equal 'database was externally modified/reset', session_data['error']

    # And recording should now be considered stopped
    refute FixtureFarm::FixtureRecorder.recording_session_in_progress?
  end
end
