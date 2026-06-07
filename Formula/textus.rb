# frozen_string_literal: true

class Textus < Formula
  desc "Durable multi-writer project memory for humans, AI, and automation"
  homepage "https://github.com/patrick204nqh/textus"
  url "https://github.com/patrick204nqh/textus/archive/refs/tags/v0.50.0.tar.gz"
  sha256 "30835c4bbf6a9cfb989c2d8b7e8ce793dcb6a12034305408d1d64fa16ddae6ba"
  license "MIT"

  # bottle-source-digest: ad2b3bf6dd6139768495ba23c26d7475bf66426d11552f787abd507b129df2cb
  bottle do
    root_url "https://github.com/patrick204nqh/homebrew-tap/releases/download/textus-v0.50.0"
    sha256 cellar: :any, arm64_sequoia: "7f01a33c73eb15a306b0863fade18b709480d07b035869a7045e771f16fdf3fa"
  end

  depends_on "gmp"

  # Bundled Ruby runtime — shared across all Ruby-based tap formulas.
  # See docs/architecture/decisions/001-arm64-only-bottles.md.
  RUBY_RUNTIME_VERSION = "3.3.11"

  resource "ruby-runtime" do
    url "https://github.com/patrick204nqh/homebrew-tap/releases/download/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}-arm64-darwin.tar.gz"
    sha256 "20d0fdb6de2cec6c8085e1edf3553f9cab3437932087ff451ca44a7727dc7a40"
  end

  # ── BEGIN generated gem resources — managed by script/gen-formula, do not edit ──
  resource "csv" do
    url "https://rubygems.org/downloads/csv-3.3.5.gem"
    sha256 "6e5134ac3383ef728b7f02725d9872934f523cb40b961479f69cf3afa6c8e73f"
  end

  resource "date" do
    url "https://rubygems.org/downloads/date-3.5.1.gem"
    sha256 "750d06384d7b9c15d562c76291407d89e368dda4d4fff957eb94962d325a0dc0"
  end

  resource "psych" do
    url "https://rubygems.org/downloads/psych-5.3.1.gem"
    sha256 "eb7a57cef10c9d70173ff74e739d843ac3b2c019a003de48447b2963d81b1974"
  end

  resource "rexml" do
    url "https://rubygems.org/downloads/rexml-3.4.4.gem"
    sha256 "19e0a2c3425dfbf2d4fc1189747bdb2f849b6c5e74180401b15734bc97b5d142"
  end

  resource "stringio" do
    url "https://rubygems.org/downloads/stringio-3.2.0.gem"
    sha256 "c37cb2e58b4ffbd33fe5cd948c05934af997b36e0b6ca6fdf43afa234cf222e1"
  end

  resource "zeitwerk" do
    url "https://rubygems.org/downloads/zeitwerk-2.8.1.gem"
    sha256 "1c85e0f28954d68cd16e575da37f26846f609b68d80b5942ccfd31030c2449d5"
  end
  # ── END generated gem resources ──

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
    # Upstream ships its executable in exe/ (gemspec bindir), not bin/.
    (libexec / "bin").install "exe/textus"

    ruby_version = Utils.safe_popen_read(
      bundled_ruby, "-e", "puts RbConfig::CONFIG['ruby_version']"
    ).chomp
    ruby_stdlib_gems = ruby_runtime / "lib/ruby/gems" / ruby_version

    env = {
      GEM_HOME: gem_home,
      GEM_PATH: "#{gem_home}#{File::PATH_SEPARATOR}#{ruby_stdlib_gems}",
      PATH:     "#{ruby_runtime / "bin"}#{File::PATH_SEPARATOR}#{ENV.fetch("PATH", nil)}",
    }
    (bin / "textus").write_env_script(libexec / "bin/textus", env)
  end

  def post_install
    # When a bottle built on an older darwin is poured on a newer one,
    # native extension .bundles land in the wrong platform directory.
    # They are binary-compatible within the same Ruby major.minor + arch,
    # so we symlink the built platform dir to the current one.
    bundled_ruby = libexec / "ruby-runtime/bin/ruby"
    current_platform = Utils.safe_popen_read(bundled_ruby, "-e", "puts Gem::Platform.local").chomp
    ext_dir = libexec / "gems/extensions"
    return unless ext_dir.exist?
    return if (ext_dir / current_platform).exist?

    ext_dir.each_child do |src|
      next unless src.directory?

      dst = ext_dir / current_platform
      dst.mkpath
      src.each_child do |ver_dir|
        next unless ver_dir.directory?

        dst_ver = dst / ver_dir.basename
        ln_sf ver_dir, dst_ver unless dst_ver.exist?
      end
    end
  end

  def caveats
    <<~EOS
      Get started:
        textus --help

      JSON is the default output. textus reads and writes a project memory
      store; see https://github.com/patrick204nqh/textus for the protocol.

      If you previously installed textus via RubyGems and use asdf, its shims
      may shadow this Homebrew install. Fix it by removing the gem:
        gem uninstall textus
        asdf reshim ruby
    EOS
  end

  test do
    # --version forces `require "textus"` and CLI activation through the
    # bundled ruby-runtime + gem chain, so a broken runtime/wrapper PATH
    # fails here even though a trivial check might pass.
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/textus --version 2>&1"))
    assert_match "Usage", shell_output("#{bin}/textus --help 2>&1")
  end

  private

  def relocate_runtime(ruby_runtime)
    system "ruby", (ruby_runtime / "relocate-runtime.rb").to_s, ruby_runtime.to_s
  end
end
