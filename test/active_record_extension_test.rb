# frozen_string_literal: true

require 'test_helper'

class ActiveRecordExtensionTest < ActiveSupport::TestCase
  test 'fixture_name returns nil when no fixtures file exists' do
    membership = Membership.create!(user: users(:existing_user), group: groups(:developers))

    fixture_file = Rails.root.join('test', 'fixtures', 'memberships.yml')
    FileUtils.rm_f(fixture_file)

    assert_nil membership.fixture_name
  end

  test 'fixture_name returns correct name when fixture exists' do
    user = users(:existing_user)
    assert_equal 'existing_user', user.fixture_name
  end

  test 'fixture_name returns nil when no matching fixture found' do
    user = User.create!(name: 'New User', email: 'new@example.com')
    assert_nil user.fixture_name
  end

  test 'fixture_name handles empty fixture file' do
    empty_file = Rails.root.join('test', 'fixtures', 'tenant_models.yml')
    FileUtils.mkdir_p(empty_file.dirname)
    File.write(empty_file, '')

    tenant = TenantModel.create!(name: 'Test Tenant')
    assert_nil tenant.fixture_name
  end

  test 'fixtures_file_path returns existing file path when file exists' do
    user = User.new

    expected_path = Rails.root.join('test', 'fixtures', 'users.yml')

    assert_equal expected_path.to_s, user.fixtures_file_path.to_s
  end

  test 'fixtures_file_path returns candidate path when no file exists' do
    tenant_model = TenantModel.new

    expected_path = Rails.root.join('test', 'fixtures', 'tenant_models.yml')

    assert_equal expected_path.to_s, tenant_model.fixtures_file_path.to_s
  end

  test 'fixtures_file_path prefers existing file over candidate' do
    Rails.root.join('test', 'fixtures', 'inherited_models.yml').unlink

    inherited_model = InheritedModel.new

    expected_path = Rails.root.join('test', 'fixtures', 'users.yml')

    assert_equal expected_path.to_path, inherited_model.fixtures_file_path.to_path
  end
end
