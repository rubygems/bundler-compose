# frozen_string_literal: true

module Bundler
  module Compose
    class CLI < Bundler::Thor
      map.reject! { |_, v| v == :help }
      (@class_options ||= {}).merge!(Bundler::CLI.class_options)

      module Common
        def self.included(klass)
          # klass.strict_args_position!
          klass.singleton_class.define_method(:handle_argument_error, lambda do |*args, **kwargs, &blk|
            Bundler::Thor.method(:handle_argument_error).call(*args, **kwargs, &blk)
          end)

          klass.singleton_class.define_method(:dispatch) do |command, given_args, given_opts, config, **kwargs, &blk|
            level = Bundler.ui.level

            separator = given_opts.index("--")
            if separator
              extra_opts = given_opts[separator.succ..]
              given_opts = given_opts[0...separator]
            end
            if extra_opts
              if extra_opts == given_args[-extra_opts.size...]
                given_args = given_args[...-extra_opts.size]
                given_args.pop if given_args.last == "--"
              end
            elsif given_opts == given_args[-given_opts.size...]
              given_args = given_args[...-given_opts.size]
            end

            super(command, given_args, given_opts, config, **kwargs) do |i|
              blk.call(i)
              i.args += extra_opts if extra_opts
              Bundler.ui.level = "silent" unless i.options["verbose"]
            end
          ensure
            Bundler.ui.level = level if Bundler.ui.level == "silent"
          end
        end

        def set_ui_level
          Bundler.ui.level = "silent" unless options["verbose"]
        end

        def check_equivalence
          Bundler.definition.ensure_equivalent_gemfile_and_lockfile
        end

        def use_path(file_name)
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

        def bundle_exec(executable)
          Bundler.reset!
          Bundler.with_unbundled_env do
            Bundler::SharedHelpers.set_env "BUNDLER_VERSION", Bundler.definition.locked_gems.bundler_version.to_s
            Bundler::SharedHelpers.set_env "BUNDLE_GEMFILE", @gemfile.to_path
            ENV["BUNDLE_PATH"] = Bundler.settings.path.use_system_gems? ? nil : path.to_path
            ENV["BUNDLE_DISABLE_EXEC_LOAD"] = "true"
            ENV["BUNDLE_AUTO_INSTALL"] = "true"

            Bundler.reset!
            Bundler.reset_settings_and_root!

            begin
              run_bundle_exec(executable)
            rescue GitError
              Bundler.ui.debug "Running `bundle install`"
              Bundler::CLI.start(["install", "--quiet"])

              run_bundle_exec(executable)
            end
          end
        end

        def run_bundle_exec(executable)
          Bundler.ui.debug "Running `#{["bundle", "exec", executable, *args].join(" ")}`"
          Bundler::CLI.start(["exec", executable, *args], debug: true)
        end
      end

      gems = Class.new(Bundler::Thor::Group) do
        desc "compose gems into the current gemfile"

        argument :gem_names, type: :array, default: []

        class_option :exec, desc: "what to exec", type: :string

        include Common

        def before
          set_ui_level
          check_equivalence
        end

        def validate_args
          return unless gem_names.empty?

          self.class.handle_argument_error(
            @_initializer.last[:current_command],
            "must give at least one gem to compose", gem_names,
            -1
          )
        end

        def use_path
          super(gem_names.join("_").tr(":", "@"))
        end

        def lockfile
          set_comment
          copy_lockfile
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
          bundle_exec(options[:exec] || extract_gem_name_and_version(gem_names.first).first)
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
      end

      register gems, :gems, "gems GEM_NAMES...", "compose gems into the current gemfile"
      map "gem" => :gems

      stop_on_unknown_option! :gems

      gemfiles = Class.new(Bundler::Thor::Group) do
        desc "compose local gemfiles into the current gemfile"

        argument :gemfiles, type: :array, default: []

        class_option :exec, desc: "what to exec", type: :string, required: true

        include Common

        def before
          set_ui_level
          check_equivalence
        end

        def validate_args
          return unless gemfiles.empty?

          self.class.handle_argument_error(
            @_initializer.last[:current_command],
            "must give at least one gemfile to compose", gemfiles,
            -1
          )
        end

        def use_path
          super(gemfiles.join("_"))
        end

        def lockfile
          set_comment
          copy_lockfile
        end

        def set_composer
          gemfiles_to_add = gemfiles.map do |gemfile|
            Pathname(gemfile).expand_path.relative_path_from(@gemfile.dirname).to_path
          end
          @composer = Bundler::Compose::Composer.new(@comment, Bundler.definition, [], gemfiles_to_add, @gemfile)
        end

        def do
          @composer.write!
          bundle_exec(options[:exec])
        end
      end

      register gemfiles, :gemfiles, "gemfiles GEMFILES...", "compose gemfiles into the current gemfile"
      map "gemfile" => :gemfiles

      stop_on_unknown_option! :gemfiles
    end
  end
end
