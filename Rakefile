# frozen_string_literal: true

require_relative "spec/support/rubygems_ext"

desc "Run specs"
task :spec do
  sh("bin/rspec")
end

namespace :dev do
  desc "Ensure dev dependencies are installed"
  task :deps do
    Spec::Rubygems.dev_setup
  end

  desc "Ensure dev dependencies are installed, and make sure no lockfile changes are generated"
  task :frozen_deps => :deps do
    Spec::Rubygems.check_source_control_changes(
      :success_message => "Development dependencies were installed and the lockfile is in sync",
      :error_message => "Development dependencies were installed but the lockfile is out of sync. Commit the updated lockfile and try again"
    )
  end
end

namespace :spec do
  desc "Ensure spec dependencies are installed"
  task :deps => "dev:deps" do
    Spec::Rubygems.install_test_deps
  end
end

# frozen_string_literal: true

require "bundler/gem_tasks"


require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]
