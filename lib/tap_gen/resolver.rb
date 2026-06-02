# frozen_string_literal: true

require "bundler"

module TapGen
  # Resolves the runtime dependency closure for an upstream project from its
  # Gemfile.lock, fully offline.
  #
  # We parse the lockfile directly with Bundler::LockfileParser rather than
  # building a Bundler::Definition: `specs_for` materializes specs, which fails
  # with GemNotFound unless every gem is installed locally. The lockfile alone
  # carries everything we need — each spec's resolved version, its source, and
  # its runtime dependencies (a lockfile records only runtime deps per gem).
  #
  # The runtime set is the transitive closure of the project gem's OWN runtime
  # dependencies. We deliberately do NOT take Bundler's `:default` group: a
  # Gemfile often lists dev tools (rake, rspec, rubocop) outside any `group`
  # block, which puts them in `:default` even though they are not runtime deps.
  # Anchoring on the project gem (the `remote: .` PATH entry) and walking its
  # deps yields exactly the gems Homebrew must vendor.
  module Resolver
    module_function

    # Returns a sorted array of [name, version] string pairs.
    def runtime_gems(source_dir)
      lockfile = File.join(source_dir, "Gemfile.lock")
      raise "missing Gemfile.lock in #{source_dir}" unless File.exist?(lockfile)

      specs = Bundler::LockfileParser.new(File.read(lockfile)).specs
      index = specs.to_h { |s| [s.name, s] }
      root  = project_root(specs, source_dir)

      closure(root, index)
        .map { |spec| [spec.name, spec.version.to_s] }
        .sort_by(&:first)
    end

    # The locked spec for the project's own gem — the `remote: .` PATH entry.
    def project_root(specs, source_dir)
      roots = specs.select { |s| local_path_source?(s.source) }
      if roots.empty?
        raise "no local path gem (remote: .) in #{source_dir}/Gemfile.lock — " \
              "the project must ship a gemspec referenced via `gemspec`"
      end
      if roots.size > 1
        raise "multiple local path gems in #{source_dir}/Gemfile.lock " \
              "(#{roots.map(&:name).join(", ")}) — cannot determine the project gem"
      end
      roots.first
    end

    def local_path_source?(source)
      source.is_a?(Bundler::Source::Path) &&
        !source.is_a?(Bundler::Source::Git) &&
        source.path.to_s == "."
    end

    # Breadth-first walk of runtime deps from `root` through the locked index.
    # `root` itself is excluded (Homebrew installs it from lib/). Raises if a
    # reachable runtime dep is not RubyGems-sourced (e.g. git), since a Homebrew
    # `resource` block cannot vendor it.
    def closure(root, index)
      visited = {}
      queue   = root.dependencies.map(&:name)
      until queue.empty?
        name = queue.shift
        next if visited.key?(name)

        spec = index[name]
        unless spec
          raise "runtime dependency #{name.inspect} is missing from the lockfile " \
                "index — the Gemfile.lock may be corrupt or incomplete"
        end

        unless spec.source.is_a?(Bundler::Source::Rubygems)
          raise "runtime dependency #{name.inspect} is not RubyGems-sourced " \
                "(#{spec.source.class}); cannot vendor it as a Homebrew resource"
        end

        visited[name] = spec
        queue.concat(spec.dependencies.map(&:name))
      end
      visited.values
    end

    private_class_method :project_root, :local_path_source?, :closure
  end
end
