# frozen_string_literal: true

require_relative "lib/bundler/compose/version"

Gem::Specification.new do |spec|
  spec.name = "bundler-compose"
  spec.version = Bundler::Compose::VERSION
  spec.authors = ["Samuel Giddins"]
  spec.email = ["segiddins@segiddins.me"]

  spec.summary = "Layer additional gems on top of an existing bundle"
  spec.description = <<~DESC
    This is a bundler subcommand called `bundle compose` that makes it easy to layer additional gems on top of an existing bundle.
  DESC
  spec.homepage = "https://github.com/segiddins/bundler-compose"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
