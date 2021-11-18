require_relative "lib/fixture_farm/version"

Gem::Specification.new do |spec|
  spec.name        = "fixture_farm"
  spec.version     = FixtureFarm::VERSION
  spec.authors     = ["artemave"]
  spec.email       = ["artemave@gmail.com"]
  spec.homepage    = "TODO"
  spec.summary     = "TODO: Summary of FixtureFarm."
  spec.description = "TODO: Description of FixtureFarm."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.1"
end
