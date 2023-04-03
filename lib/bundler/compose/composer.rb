# frozen_string_literal: true

module Bundler
  module Compose
    class Composer
      attr_reader :definition

      def initialize(comment, definition, gems_to_add, _gemfiles_to_eval, gemfile)
        @comment = comment
        @definition = definition
        @gems_to_add = gems_to_add
        @gemfile = gemfile
      end

      def to_s
        [
          @comment,
          commented(platforms, "Platforms found in the lockfile"),
          commented(global_sources, "Global sources from gemfile"),
          commented(composed_gems, "Composed dependencies"),
          commented(composed_gemfiles, ""),
          commented(explicit_deps, "Original deps from gemfile"),
          commented(implicit_deps, "Deps from Gemfile.lock")
        ].compact.map { Array(_1).join("\n") }.join("\n\n") << "\n"
      end

      def write!
        Bundler::SharedHelpers.write_to_gemfile(@gemfile, to_s)
      end

      private

      def platforms
        @definition.platforms.map do |p|
          "platform(#{p.to_s.dump}) {}"
        end
      end

      def global_sources
        @definition.send(:sources).global_rubygems_source.remotes.map { %(source #{_1.to_s.dump}) }
      end

      def composed_gems
        dependencies_to_gemfile(@gems_to_add)
      end

      def composed_gemfiles
        nil
      end

      def explicit_deps
        dependencies_to_gemfile(@definition.dependencies)
      end

      def implicit_deps
        dependency_names = @definition.dependencies.group_by(&:name)
        dependencies_to_gemfile(@definition.resolve.map do |s|
          next if dependency_names.key?(s.name)

          Bundler::Dependency.new(s.name, s.version, "platform" => s.platform, "source" => s.source,
                                                     "group" => %i[bundler_compose])
        end.compact)
      end

      def dependencies_to_gemfile(dependencies)
        dependencies.group_by(&:groups).each_key(&:sort!).sort_by(&:first).each
                    .with_object([]) do |(groups, deps), lines|
          groups = nil if groups.empty? || groups == %i[default]
          optional = groups == %i[bundler_compose] ? ", optional: true" : nil
          lines << "group #{groups.map(&:inspect).join(", ")}#{optional} do" if groups

          deps.sort_by(&:name).each do |d|
            spec = Bundler.definition.resolve[d.name].first

            da = []
            da << "  " if groups

            unless d.source.is_a?(Bundler::Source::Gemspec)
              da << "gem "
              da << d.name.dump
              if spec
                da << ", #{Gem::Requirement.new(spec.version).as_list.map(&:inspect).join(", ")}"
              elsif !d.requirement.none? # rubocop:disable Style/InverseMethods
                da << ", #{d.requirement.as_list.map(&:inspect).join(", ")}"
              end
            end

            da << if d.source.nil? && spec
                    source_to_options(spec.source)
                  else
                    source_to_options(d.source)
                  end
            da << ", platforms: " << d.platforms.inspect unless d.platforms.empty?
            if (env = d.instance_variable_get(:@env))
              da << ", env: " << env.inspect
            end
            if ((req = d.autorequire)) && !req.empty?
              req = req.first if req.size == 1
              da << ", require: " << req.inspect
            end

            lines << da.join
          end

          lines << "end" if groups
        end
      end

      def source_to_options(source)
        case source
        when nil
          nil
        when Bundler::Source::Rubygems
          if source.remotes.size == 1
            %(, source: #{source.send(:suppress_configured_credentials,
                                      source.remotes.first).to_s.dump})
          end
        when Bundler::Source::Gemspec
          path = source.options["root_path"].join(source.options["path"])
                       .relative_path_from(@gemfile.dirname).to_path.dump
          s = "gemspec path: #{path}, " \
            "name: #{source.options["gemspec"].name.dump}"
          s << ", glob: #{source.options["glob"].dump}" if source.options["glob"]
          s
        else
          raise Error, "Unhandled source type #{source.inspect}"
        end
      end

      def commented(section, comment)
        return unless section

        section = Array(section)
        return if section.empty?

        comment = "#{"#" * 80}\n#{comment.gsub(/(.{1,#{80 - 4}})(\s+|$)/, "# \\1\n")}#{"#" * 80}"

        section.insert(0, comment, nil)
      end
    end
  end
end
