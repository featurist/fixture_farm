# frozen_string_literal: true

require_relative 'lib/fixture_farm/version'

Gem::Specification.new do |spec|
  spec.name        = 'fixture_farm'
  spec.version     = FixtureFarm::VERSION
  spec.authors     = ['artemave']
  spec.email       = ['mr@artem.rocks']
  spec.homepage    = 'https://github.com/featurist/fixture_farm'
  spec.summary     = 'Generate rails fixutures while browsing'
  spec.license     = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/featurist/fixture_farm.git'

  spec.files = Dir['lib/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['fixture_farm', 'fixture_farm.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 6.1.4.1'
end
