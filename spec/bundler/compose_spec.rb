# frozen_string_literal: true

RSpec.describe Bundler::Compose do
  it "has a version number" do
    expect(Bundler::Compose::VERSION).not_to be nil
  end

  context "with an empty gemfile" do
    it "adds a gem via bundle compose gems" do
      # setup

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file://#{gem_repo1}/
            specs:

          PLATFORMS
            #{local_platform}

          DEPENDENCIES

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE
      )

      # compose

      bundle "compose gems rails"
      expect(last_command.stdout).to end_with("\n2.3.2")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/rails/gems.rails.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:85a8a384f4b322cebcf8f0a54eb11b235da3eb7f50676c251c7cf727317ee31d

          ################################################################################
          # Platforms found in the lockfile
          ################################################################################

          platform("#{local_platform}") {}

          ################################################################################
          # Global sources from gemfile
          ################################################################################

          source "file://#{gem_repo1}/"

          ################################################################################
          # Composed dependencies
          ################################################################################

          gem "rails"
        RUBY

        ".bundle/bundler-compose/rails/gems.rails.rb.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file:///Users/segiddins/Development/github.com/segiddins/bundler-compose/tmp/1/gems/remote1/
            specs:
              actionmailer (2.3.2)
                activesupport (= 2.3.2)
              actionpack (2.3.2)
                activesupport (= 2.3.2)
              activerecord (2.3.2)
                activesupport (= 2.3.2)
              activeresource (2.3.2)
                activesupport (= 2.3.2)
              activesupport (2.3.2)
              rails (2.3.2)
                actionmailer (= 2.3.2)
                actionpack (= 2.3.2)
                activerecord (= 2.3.2)
                activeresource (= 2.3.2)
                rake (= 13.0.1)
              rake (13.0.1)

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            rails

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist,
      )

      bundle "compose gems rails"
      expect(last_command.stdout).to eq("2.3.2")
    end

    it "adds multiple gems via bundle compose gems" do
      # setup

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file://#{gem_repo1}/
            specs:

          PLATFORMS
            #{local_platform}

          DEPENDENCIES

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE
      )

      # compose

      bundle "compose gems rails rack-obama"
      expect(last_command.stdout).to end_with("\n2.3.2")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/rails_rack-obama/gems.rails_rack-obama.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:85a8a384f4b322cebcf8f0a54eb11b235da3eb7f50676c251c7cf727317ee31d

          ################################################################################
          # Platforms found in the lockfile
          ################################################################################

          platform("#{local_platform}") {}

          ################################################################################
          # Global sources from gemfile
          ################################################################################

          source "file://#{gem_repo1}/"

          ################################################################################
          # Composed dependencies
          ################################################################################

          gem "rack-obama"
          gem "rails"
        RUBY

        ".bundle/bundler-compose/rails_rack-obama/gems.rails_rack-obama.rb.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file:///Users/segiddins/Development/github.com/segiddins/bundler-compose/tmp/1/gems/remote1/
            specs:
              actionmailer (2.3.2)
                activesupport (= 2.3.2)
              actionpack (2.3.2)
                activesupport (= 2.3.2)
              activerecord (2.3.2)
                activesupport (= 2.3.2)
              activeresource (2.3.2)
                activesupport (= 2.3.2)
              activesupport (2.3.2)
              rack (1.0.0)
              rack-obama (1.0)
                rack
              rails (2.3.2)
                actionmailer (= 2.3.2)
                actionpack (= 2.3.2)
                activerecord (= 2.3.2)
                activeresource (= 2.3.2)
                rake (= 13.0.1)
              rake (13.0.1)

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            rack-obama
            rails

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist,
      )

      bundle "compose gems rails"
      expect(last_command.stdout).to eq("2.3.2")
    end
  end

  context "in an existing bundle" do
    it "adds an  existing gem via bundle compose gems" do
      # setup

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"

        gem "rails", "~> 2.2", require: false

        group :development, :test do
          gem "rspec"
        end
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file://#{gem_repo1}/
            specs:
              actionmailer (2.3.2)
                activesupport (= 2.3.2)
              actionpack (2.3.2)
                activesupport (= 2.3.2)
              activerecord (2.3.2)
                activesupport (= 2.3.2)
              activeresource (2.3.2)
                activesupport (= 2.3.2)
              activesupport (2.3.2)
              rails (2.3.2)
                actionmailer (= 2.3.2)
                actionpack (= 2.3.2)
                activerecord (= 2.3.2)
                activeresource (= 2.3.2)
                rake (= 13.0.1)
              rake (13.0.1)
              rspec (1.2.7)

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            rails (~> 2.2)
            rspec

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE
      )

      # compose

      bundle "compose gems rails"
      expect(last_command.stdout).to eq("2.3.2")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/rails/gems.rails.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:4ba7b5eabb555785a99972001ccb0fccf6a83c9c74830e83515a7e9108a1ae3a

          ################################################################################
          # Platforms found in the lockfile
          ################################################################################

          platform("#{local_platform}") {}

          ################################################################################
          # Global sources from gemfile
          ################################################################################

          source "file://#{gem_repo1}/"

          ################################################################################
          # Composed dependencies
          ################################################################################

          gem "rails", "= 2.3.2", source: "file://#{gem_repo1}/"

          ################################################################################
          # Original deps from gemfile
          ################################################################################

          gem "rails", "= 2.3.2", source: "file://#{gem_repo1}/"
          group :development, :test do
            gem "rspec", "= 1.2.7", source: "file://#{gem_repo1}/"
          end

          ################################################################################
          # Deps from Gemfile.lock
          ################################################################################

          group :bundler_compose, optional: true do
            gem "actionmailer", "= 2.3.2", source: "file://#{gem_repo1}/"
            gem "actionpack", "= 2.3.2", source: "file://#{gem_repo1}/"
            gem "activerecord", "= 2.3.2", source: "file://#{gem_repo1}/"
            gem "activeresource", "= 2.3.2", source: "file://#{gem_repo1}/"
            gem "activesupport", "= 2.3.2", source: "file://#{gem_repo1}/"
            gem "rake", "= 13.0.1", source: "file://#{gem_repo1}/"
          end
        RUBY

        ".bundle/bundler-compose/rails/gems.rails.rb.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file://#{gem_repo1}/
            specs:
              actionmailer (2.3.2)
                activesupport (= 2.3.2)
              actionpack (2.3.2)
                activesupport (= 2.3.2)
              activerecord (2.3.2)
                activesupport (= 2.3.2)
              activeresource (2.3.2)
                activesupport (= 2.3.2)
              activesupport (2.3.2)
              rails (2.3.2)
                actionmailer (= 2.3.2)
                actionpack (= 2.3.2)
                activerecord (= 2.3.2)
                activeresource (= 2.3.2)
                rake (= 13.0.1)
              rake (13.0.1)
              rspec (1.2.7)

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            actionmailer (= 2.3.2)!
            actionpack (= 2.3.2)!
            activerecord (= 2.3.2)!
            activeresource (= 2.3.2)!
            activesupport (= 2.3.2)!
            rails (= 2.3.2)!
            rake (= 13.0.1)!
            rspec (= 1.2.7)!

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist,
      )
    end
  end
end
