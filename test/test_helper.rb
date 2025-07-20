# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'
require_relative '../lib/fixture_farm/fixture_recorder'

require 'rails/test_help'

# Set up in-memory database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load schema into memory database
ActiveRecord::Schema.verbose = false
load Rails.root.join('db', 'schema.rb')

module ActiveSupport
  class TestCase
    self.use_transactional_tests = true

    fixtures :all

    setup do
      FakeFS.activate!
      FakeFS::FileSystem.clone(Rails.root)

      # Clone locale files so I18n works (model validation errors)
      %w[active_model active_record action_view active_support].each do |gem_name|
        locale_path = File.join(Gem.loaded_specs[gem_name.sub('_', '')].full_gem_path, 'lib', gem_name, 'locale')
        FakeFS::FileSystem.clone(locale_path)
      end

      locale_path = File.join(Gem.loaded_specs['actionpack'].full_gem_path, 'lib', 'action_dispatch', 'middleware',
                              'templates')
      FakeFS::FileSystem.clone(locale_path)
    end

    teardown do
      FixtureFarm::FixtureRecorder.stop_recording_session!
      FakeFS.deactivate!
    end
  end
end
