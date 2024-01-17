# frozen_string_literal: true

RSpec.describe Bundler::Compose do
  it "has a version number" do
    expect(Bundler::Compose::VERSION).not_to be nil
  end

  context "when invoking help" do
    it "prints help for bundle compose" do
      bundle "compose help"
      expect(last_command.stdout).to eq(<<~HELP.chomp)
        Commands:
          bundle compose gemfiles GEMFILES...  # compose gemfiles into the current gemfile
          bundle compose gems GEM_NAMES...     # compose gems into the current gemfile
          bundle compose help [COMMAND]        # Describe subcommands or one specific subcommand

        Options:
              [--no-color]                 # Disable colorization in output
          -r, [--retry=NUM]                # Specify the number of times you wish to attempt network commands
          -V, [--verbose], [--no-verbose]  # Enable verbose output mode
      HELP
    end

    it "prints help for bundle compose gems" do
      bundle "compose help gems"
      expect(last_command.stdout).to eq(<<~HELP.chomp)
        Usage:
          bundle compose gems GEM_NAMES...

        Options:
              [--no-color]                 # Disable colorization in output
          -r, [--retry=NUM]                # Specify the number of times you wish to attempt network commands
          -V, [--verbose], [--no-verbose]  # Enable verbose output mode

        compose gems into the current gemfile
      HELP
    end

    it "prints help for bundle compose gemfiles" do
      bundle "compose help gemfiles"
      expect(last_command.stdout).to eq(<<~HELP.chomp)
        Usage:
          bundle compose gemfiles GEMFILES...

        Options:
              [--no-color]                 # Disable colorization in output
          -r, [--retry=NUM]                # Specify the number of times you wish to attempt network commands
          -V, [--verbose], [--no-verbose]  # Enable verbose output mode

        compose gemfiles into the current gemfile
      HELP
    end
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
        "Gemfile.lock" => read_as(<<~LOCKFILE)
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
          # lockfile:../../../Gemfile:#{sha256(lockfile)}

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

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            rails

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist
      )

      bundle "compose gems rails"
      expect(last_command.stdout).to eq("2.3.2")
    end

    it "forwards arguments via bundle compose gems" do
      # setup

      build_repo2 do
        build_gem "argv", "1.0.0" do |s|
          s.executables = "argv"
          s.write "bin/argv", "puts ARGV"
        end
      end

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo2}"
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE)
          GEM
            remote: file://#{gem_repo2}/
            specs:

          PLATFORMS
            #{local_platform}

          DEPENDENCIES

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE
      )

      # compose

      bundle "compose gem argv"

      bundle "compose gem argv"
      expect(last_command.stdout.lines).to eq([])

      bundle "compose gems argv -- arg1 --opt arg2"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[arg1 --opt arg2])

      bundle "compose gem argv -- arg1 --opt arg2"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[arg1 --opt arg2])
      bundle "compose gem argv --exec argv"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[])
      bundle "compose gem --exec argv argv"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[])
      bundle "compose gem argv --version"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[--version])
      bundle "compose gem argv -- --verbose"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[--verbose])

      # Needs a change to Bundler::CLI.reformatted_help_args
      # to not reformat when the command is unknown

      # bundle "compose gem argv -- --help"
      # expect(last_command.stdout.lines(chomp: true)).to eq(%w[--help])
      # bundle "compose gem argv --help"
      # expect(last_command.stdout.lines(chomp: true)).to eq(%w[--help])

      bundle "compose gem rack --exec argv argv -- arg1 --opt arg2 --exec rack"
      bundle "compose gem rack --exec argv argv -- arg1 --opt arg2 --exec rack"
      expect(last_command.stdout.lines(chomp: true)).to eq(%w[arg1 --opt arg2 --exec rack])
    end

    it "adds a gemfile via bundle compose gemfiles" do
      # setup

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE)
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

      bundled_app("gems.devtools.rb").write(<<~RUBY)
        group :development do
          gem "thin", source: "file://#{gem_repo1}", require: false
        end
      RUBY

      bundle "compose gemfiles gems.devtools.rb --exec ruby -e 'puts Gem.loaded_specs.values.map(&:full_name).sort'"
      pathname_version = Gem::Specification.default_stubs("pathname-*.gemspec").map(&:version).max
      expect(last_command.stdout)
        .to end_with("\nbundler-#{Bundler::VERSION}\npathname-#{pathname_version}\nrack-1.0.0\nthin-1.0")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/gems.devtools.rb/gems.gems.devtools.rb.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:#{sha256(lockfile)}

          ################################################################################
          # Platforms found in the lockfile
          ################################################################################

          platform("#{local_platform}") {}

          ################################################################################
          # Global sources from gemfile
          ################################################################################

          source "file://#{gem_repo1}/"

          ################################################################################
          # Composed gemfiles
          ################################################################################

          eval_gemfile "../../../gems.devtools.rb"
        RUBY

        ".bundle/bundler-compose/gems.devtools.rb/gems.gems.devtools.rb.rb.lock" => read_as(<<~LOCKFILE),
          GEM
            remote: file://#{gem_repo1}/
            specs:
              rack (1.0.0)
              thin (1.0)
                rack

          PLATFORMS
            #{local_platform}

          DEPENDENCIES
            thin!

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist,
        "gems.devtools.rb" => exist
      )

      bundle "compose gemfiles gems.devtools.rb --exec ruby -e 'puts Gem.loaded_specs.values.map(&:full_name).sort'"
      pathname_version = Gem::Specification.default_stubs("pathname-*.gemspec").map(&:version).max
      expect(last_command.stdout)
        .to eq("bundler-#{Bundler::VERSION}\npathname-#{pathname_version}\nrack-1.0.0\nthin-1.0")
    end

    it "adds multiple gems via bundle compose gems" do
      # setup

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE)
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

      bundle "compose gems rails rack-obama:1"
      expect(last_command.stdout).to end_with("\n2.3.2")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/rails_rack-obama@1/gems.rails_rack-obama@1.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:#{sha256(lockfile)}

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

          gem "rack-obama", "= 1"
          gem "rails"
        RUBY

        ".bundle/bundler-compose/rails_rack-obama@1/gems.rails_rack-obama@1.rb.lock" => read_as(<<~LOCKFILE),
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
            rack-obama (= 1)
            rails

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist
      )

      bundle "compose gems rails"
      expect(last_command.stdout).to eq("2.3.2")
    end
  end

  context "with an existing bundle" do
    it "adds an existing gem via bundle compose gems" do
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
        "Gemfile.lock" => read_as(<<~LOCKFILE)
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
          # lockfile:../../../Gemfile:#{sha256(lockfile)}

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
        "Gemfile.lock" => exist
      )
    end

    it "adds an existing gem via bundle compose gems to a bundle with git gems" do
      # setup

      g = build_git "rack", "1.0.0", path: lib_path("rack")

      bundled_app("Gemfile").write(<<~RUBY)
        source "file://#{gem_repo1}"

        gem "rails", "~> 2.2", require: false
        gem "rack", git: #{lib_path("rack").to_s.dump}, require: false

        group :development, :test do
          gem "rspec"
        end
      RUBY

      bundle :install

      expect(the_bundle).to match_fs(
        "Gemfile" => exist,
        "Gemfile.lock" => read_as(<<~LOCKFILE)
          GIT
            remote: #{lib_path("rack")}
            revision: #{g.ref_for("HEAD")}
            specs:
              rack (1.0.0)

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
            rack!
            rails (~> 2.2)
            rspec

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE
      )

      # compose

      bundle "compose gems rails", verbose: true
      expect(last_command.stdout).to eq("2.3.2")

      # diff

      expect(the_bundle).to match_fs(
        ".bundle/bundler-compose/rails/gems.rails.rb" => read_as(<<~RUBY),
          # lockfile:../../../Gemfile:#{sha256(lockfile)}

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

          gem "rack", "= 1.0.0", git: #{lib_path("rack").to_s.dump}
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
          GIT
            remote: #{lib_path("rack")}
            revision: #{g.ref_for("HEAD")}
            specs:
              rack (1.0.0)

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
            rack (= 1.0.0)!
            rails (= 2.3.2)!
            rake (= 13.0.1)!
            rspec (= 1.2.7)!

          BUNDLED WITH
             #{Bundler::VERSION}
        LOCKFILE

        "Gemfile" => exist,
        "Gemfile.lock" => exist
      )
    end
  end
end
