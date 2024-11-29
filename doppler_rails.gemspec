# frozen_string_literal: true

require_relative "lib/doppler_rails/version"

Gem::Specification.new do |spec|
  spec.name = "doppler_rails"
  spec.version = DopplerRails::VERSION
  spec.authors = ["Jonas Brusman", "Björn Nordstrand"]

  spec.summary = "Fetch environment variables from Doppler and inject them into your Rails application."
  spec.homepage = "https://github.com/teamtailor/doppler_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/teamtailor/doppler_rails"
  spec.metadata["changelog_uri"] = "https://github.com/teamtailor/doppler_rails/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "faraday", ">= 1.0", "< 2.0"
  spec.add_dependency "rails", ">= 6.0", "< 8.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
