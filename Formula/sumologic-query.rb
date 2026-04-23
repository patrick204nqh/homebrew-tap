# frozen_string_literal: true

class SumologicQuery < Formula
  desc "Lightweight Ruby CLI for querying Sumo Logic logs quickly"
  homepage "https://github.com/patrick204nqh/sumologic-query"
  url "https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "4282fc7daa74ffd3a4d37bf87447b1282cd3ec7ee4217f63bd17a84592610620"
  license "MIT"

  bottle do
    root_url "https://github.com/patrick204nqh/homebrew-tap/releases/download/sumologic-query-1.4.2"
    rebuild 1
    sha256 cellar: :any, arm64_sequoia: "8abbc9a4480be35cafb3fb7bd8116b3069ddcf373a207aa4ae53660488e3a0ff"
  end

  depends_on "gmp"

  # Shared relocatable Ruby runtime — built by .github/workflows/build-ruby-runtime.yml.
  # Run that workflow once per Ruby version bump; all Ruby-based tap formulas share this release.
  # See docs/architecture/diagrams/04-build-ruby-runtime-manual.png for the full picture.
  RUBY_RUNTIME_VERSION = "3.3.6"

  resource "ruby-runtime" do
    url "https://github.com/patrick204nqh/homebrew-tap/releases/download/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}-arm64-darwin.tar.gz"
    sha256 "f50b5e2ff624197745f91e3c8b5cf466f1e185e4fe8686e5ec8c90b7cd0776ff"
  end

  resource "thor" do
    url "https://rubygems.org/downloads/thor-1.3.2.gem"
    sha256 "eef0293b9e24158ccad7ab383ae83534b7ad4ed99c09f96f1a6b036550abbeda"
  end

  resource "base64" do
    url "https://rubygems.org/downloads/base64-0.2.0.gem"
    sha256 "0f25e9b21a02a0cc0cea8ef92b2041035d39350946e8789c562b2d1a3da01507"
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
