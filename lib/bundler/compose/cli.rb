# frozen_string_literal: true

module Bundler
  module Compose
    class CLI < Bundler::Thor
      (@class_options ||= {}).merge!(Bundler::CLI.class_options)

      register (Class.new(Bundler::Thor::Group) do
        desc "compose gems into the current gemfile"

        argument :gem_names, type: :array, default: []

        class_option :exec, desc: "what to exec", type: :string

        def set_ui_level
          Bundler.ui.level = "silent" unless options["verbose"]
        end

        def validate_args
          return unless gem_names.empty?

          self.class.handle_argument_error(
            @_initializer.last[:current_command],
            "must give at least one gem to compose", gem_names,
            -1
          )
        end

        def check_equivalence
          Bundler.definition.ensure_equivalent_gemfile_and_lockfile
        end

        def set_path
          file_name = gem_names.join("_").tr(":", "@")
          @path = Bundler.app_config_path.join("bundler-compose", file_name)
          @gemfile = @path.join("gems.#{file_name}.rb")
          @lockfile = @path.join("gems.#{file_name}.rb.lock")
          Bundler.mkdir_p @path
        end

        def set_comment
          @comment = [
            "# lockfile",
            Bundler.default_gemfile.relative_path_from(@gemfile.dirname),
            Bundler::SharedHelpers.digest(:SHA256).hexdigest(Bundler.read_file(Bundler.default_lockfile))
          ].join(":")
        end

        def copy_lockfile
          lockfile_up_to_date = Bundler::SharedHelpers.filesystem_access(@gemfile, :read) do
            File.read(@gemfile, @comment.length, external_encoding: "UTF-8") == @comment
          rescue Errno::ENOENT
            false
          end

          Bundler::FileUtils.cp(Bundler.default_lockfile, @lockfile) unless lockfile_up_to_date
        end

        def set_composer
          gems_to_add = gem_names.map do
            n, v = extract_gem_name_and_version(_1)
            Bundler::Dependency.new(n, v)
          end
          @composer = Bundler::Compose::Composer.new(@comment, Bundler.definition, gems_to_add, [], @gemfile)
        end

        def do
          @composer.write!
        end

        def bundle_exec
          Bundler.reset!
          Bundler.with_unbundled_env do
            Bundler::SharedHelpers.set_env "BUNDLER_VERSION", Bundler.definition.locked_gems.bundler_version.to_s
            Bundler::SharedHelpers.set_env "BUNDLE_GEMFILE", @gemfile.to_path
            ENV["BUNDLE_PATH"] = Bundler.settings.path.use_system_gems? ? nil : path.to_path
            ENV["BUNDLE_DISABLE_EXEC_LOAD"] = "true"
            ENV["BUNDLE_AUTO_INSTALL"] = "true"

            Bundler.reset!
            Bundler.reset_settings_and_root!

            Bundler::CLI.start(["exec", extract_gem_name_and_version(gem_names.first).first, *args], debug: true)
          end
        end

        no_commands do
          def extract_gem_name_and_version(name)
            if /\A(.*):(#{Gem::Requirement::PATTERN_RAW})\z/ =~ name
              [::Regexp.last_match(1), ::Regexp.last_match(2)]
            else
              [name]
            end
          end
        end

        def self.handle_argument_error(...)
          Bundler::Thor.method(:handle_argument_error).call(...)
        end
      end), :gems, "gems GEM_NAMES...", "compose gems into the current gemfile"

      map gem: :gems
    end
  end
end
