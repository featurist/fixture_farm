# frozen_string_literal: true

module FixtureFarm
  module ActiveRecordExtension
    def fixture_name
      require 'active_record/fixtures'

      return nil unless File.exist?(fixtures_file_path)

      fixtures = YAML.load_file(fixtures_file_path)
      fixtures.keys.find do |key|
        ActiveRecord::FixtureSet.identify(key) == id
      end
    end

    def fixtures_file_path
      existing_fixtures_file_path || candidate_fixtures_file_path
    end

    def candidate_fixtures_file_path
      klass = self.class
      loop do
        path = Rails.root.join('test', 'fixtures', "#{klass.to_s.underscore.pluralize}.yml")
        return path if klass >= ActiveRecord::Base || !klass.columns.map(&:name).include?(klass.inheritance_column)

        klass = klass.superclass
      end
    end

    def existing_fixtures_file_path
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
