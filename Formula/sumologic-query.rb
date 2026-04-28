# frozen_string_literal: true

class SumologicQuery < Formula
  desc "Lightweight Ruby CLI for querying Sumo Logic logs quickly"
  homepage "https://github.com/patrick204nqh/sumologic-query"
  url "https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "4282fc7daa74ffd3a4d37bf87447b1282cd3ec7ee4217f63bd17a84592610620"
  license "MIT"

  bottle do
    root_url "https://github.com/patrick204nqh/homebrew-tap/releases/download/tap-pr-21"
    rebuild 4
    sha256 cellar: :any, arm64_sequoia: "a3367a1ded5049ff13835d35bc3b4beca588421e2613846f25210fd04d792e3d"
  end

  depends_on "gmp"

  # Shared relocatable Ruby runtime — built by .github/workflows/build-ruby-runtime.yml.
  # Run that workflow once per Ruby version bump; all Ruby-based tap formulas share this release.
  # See docs/architecture/diagrams/04-build-ruby-runtime-manual.png for the full picture.
  RUBY_RUNTIME_VERSION = "3.3.11"

  resource "ruby-runtime" do
    url "https://github.com/patrick204nqh/homebrew-tap/releases/download/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}-arm64-darwin.tar.gz"
    sha256 "20d0fdb6de2cec6c8085e1edf3553f9cab3437932087ff451ca44a7727dc7a40"
  end

  resource "thor" do
    url "https://rubygems.org/downloads/thor-1.5.0.gem"
    sha256 "e3a9e55fe857e44859ce104a84675ab6e8cd59c650a49106a05f55f136425e73"
  end

  resource "base64" do
    url "https://rubygems.org/downloads/base64-0.3.0.gem"
    sha256 "27337aeabad6ffae05c265c450490628ef3ebd4b67be58257393227588f5a97b"
  end

  def install
    ruby_runtime = libexec / "ruby-runtime"
    resource("ruby-runtime").stage { ruby_runtime.install Dir["*"] }

    bundled_ruby = ruby_runtime / "bin/ruby"
    bundled_gem  = ruby_runtime / "bin/gem"
    gem_home     = libexec / "gems"

    relocate_runtime(ruby_runtime)

    ENV["GEM_HOME"] = gem_home

    (resources - [resource("ruby-runtime")]).each do |r|
      r.stage do
        system bundled_gem, "install", r.cached_download,
               "--no-document", "--ignore-dependencies", "--install-dir", gem_home
      end
    end

    libexec.install "lib"
    (libexec / "bin").install "bin/sumo-query"

    ruby_version = Utils.safe_popen_read(bundled_ruby, "-e", "puts RbConfig::CONFIG['ruby_version']").chomp
    ruby_stdlib_gems = ruby_runtime / "lib/ruby/gems" / ruby_version

    env = {
      GEM_HOME: gem_home,
      GEM_PATH: "#{gem_home}#{File::PATH_SEPARATOR}#{ruby_stdlib_gems}",
      PATH:     "#{ruby_runtime / "bin"}#{File::PATH_SEPARATOR}#{ENV.fetch("PATH", nil)}",
    }
    (bin / "sumo-query").write_env_script(libexec / "bin/sumo-query", env)
  end

  def caveats
    <<~EOS
      Set up Sumo Logic API credentials:
        export SUMO_ACCESS_ID='your_access_id'
        export SUMO_ACCESS_KEY='your_access_key'
        export SUMO_DEPLOYMENT='us2'  # Optional: us1, us2 (default), eu, au

      Get API credentials from:
        Sumo Logic → Administration → Security → Access Keys

      View commands:
        sumo-query help
    EOS
  end

  test do
    assert_match "Commands:", shell_output("#{bin}/sumo-query help")
    assert_match "search", shell_output("#{bin}/sumo-query help")
    assert_match "list-collectors", shell_output("#{bin}/sumo-query help")
    assert_match "list-sources", shell_output("#{bin}/sumo-query help")
  end

  private

  def relocate_runtime(ruby_runtime)
    system "ruby", (ruby_runtime / "relocate-runtime.rb").to_s, ruby_runtime.to_s
  end
end
