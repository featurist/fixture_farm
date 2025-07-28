# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'

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
    concerning :DummyAppIsolation do
      included do
        cattr_accessor :tmp_dir
      end

      def setup_dummy_app
        tmp_dir = Dir.mktmpdir
        dummy_app_path = File.expand_path('./dummy', __dir__)
        FileUtils.cp_r("#{dummy_app_path}/.", tmp_dir)

        Rails.define_singleton_method(:root) { Pathname.new(tmp_dir) }

        ActiveStorage::Blob.service.root = Rails.root.join('storage')

        Rails.application.reload_routes!
      end

      def teardown_dummy_app
        FileUtils.remove_entry(self.class.tmp_dir) if self.class.tmp_dir
      end
    end

    self.use_transactional_tests = true

    fixtures :all

    setup do
      setup_dummy_app
    end

    teardown do
      FixtureFarm::FixtureRecorder.stop_recording_session!
      teardown_dummy_app
    end
  end
end
