# frozen_string_literal: true

module FixtureFarm
  module ActiveRecordExtension
    def fixture_name
      require 'active_record/fixtures'

      return nil unless fixture_file_path

      fixtures = YAML.load_file(fixture_file_path)
      fixtures.keys.find do |key|
        ActiveRecord::FixtureSet.identify(key) == id
      end
    end

    def fixture_file_path
      klass = self.class

      while klass < ActiveRecord::Base
        path = Rails.root.join('test', 'fixtures', "#{klass.to_s.underscore.pluralize}.yml")
        return path if File.exist?(path)

        klass = klass.superclass
      end

      nil
    end
  end
end
