# frozen_string_literal: true

class Textus < Formula
  desc "Durable multi-writer project memory for humans, AI, and automation"
  homepage "https://github.com/patrick204nqh/textus"
  url "https://github.com/patrick204nqh/textus/archive/refs/tags/v0.55.2.tar.gz"
  sha256 "85aa1a4fa3ba4c9e99a725c8335f9b46552af22a8e7a4ef5ae4ef680b2398bab"
  license "MIT"

  # bottle-source-digest: 16dab4f66284412fa23ed078ef4443306417191f234970654352cf33d17e8a1c
  bottle do
    root_url "https://github.com/patrick204nqh/homebrew-tap/releases/download/textus-v0.55.2"
    sha256 cellar: :any, arm64_sequoia: "2ab68ee92f06ae02fd3a1e682220aaf7fdc9942085c72fe66c94960ca8a0d768"
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
  resource "bigdecimal" do
    url "https://rubygems.org/downloads/bigdecimal-4.1.2.gem"
    sha256 "53d217666027eab4280346fba98e7d5b66baaae1b9c3c1c0ffe89d48188a3fbd"
  end

  resource "concurrent-ruby" do
    url "https://rubygems.org/downloads/concurrent-ruby-1.3.6.gem"
    sha256 "6b56837e1e7e5292f9864f34b69c5a2cbc75c0cf5338f1ce9903d10fa762d5ab"
  end

  resource "csv" do
    url "https://rubygems.org/downloads/csv-3.3.5.gem"
    sha256 "6e5134ac3383ef728b7f02725d9872934f523cb40b961479f69cf3afa6c8e73f"
  end

  resource "date" do
    url "https://rubygems.org/downloads/date-3.5.1.gem"
    sha256 "750d06384d7b9c15d562c76291407d89e368dda4d4fff957eb94962d325a0dc0"
  end

  resource "dry-configurable" do
    url "https://rubygems.org/downloads/dry-configurable-1.4.0.gem"
    sha256 "e35d1b5f3c081753ef361f564919db79000f32cfa6f20ee3a3ba5921b41b73ce"
  end

  resource "dry-core" do
    url "https://rubygems.org/downloads/dry-core-1.2.0.gem"
    sha256 "0cc5a7da88df397f153947eeeae42e876e999c1e30900f3c536fb173854e96a1"
  end

  resource "dry-inflector" do
    url "https://rubygems.org/downloads/dry-inflector-1.3.1.gem"
    sha256 "7fb0c2bb04f67638f25c52e7ba39ab435d922a3a5c3cd196120f63accb682dcc"
  end

  resource "dry-initializer" do
    url "https://rubygems.org/downloads/dry-initializer-3.2.0.gem"
    sha256 "37d59798f912dc0a1efe14a4db4a9306989007b302dcd5f25d0a2a20c166c4e3"
  end

  resource "dry-logic" do
    url "https://rubygems.org/downloads/dry-logic-1.6.0.gem"
    sha256 "da6fedbc0f90fc41f9b0cc7e6f05f5d529d1efaef6c8dcc8e0733f685745cea2"
  end

  resource "dry-schema" do
    url "https://rubygems.org/downloads/dry-schema-1.16.0.gem"
    sha256 "cd3aaeabc0f1af66ec82a29096d4c4fb92a0a58b9dae29a22b1bbceb78985727"
  end

  resource "dry-struct" do
    url "https://rubygems.org/downloads/dry-struct-1.8.1.gem"
    sha256 "033868594c45241540172bf1ebbc8bb76b72b4f0717072325deba38ac13e80f1"
  end

  resource "dry-types" do
    url "https://rubygems.org/downloads/dry-types-1.9.1.gem"
    sha256 "baebeecdb9f8395d6c9d227b62011279440943e3ef2468fe8ccc1ba11467f178"
  end

  resource "hana" do
    url "https://rubygems.org/downloads/hana-1.3.7.gem"
    sha256 "5425db42d651fea08859811c29d20446f16af196308162894db208cac5ce9b0d"
  end

  resource "ice_nine" do
    url "https://rubygems.org/downloads/ice_nine-0.11.2.gem"
    sha256 "5d506a7d2723d5592dc121b9928e4931742730131f22a1a37649df1c1e2e63db"
  end

  resource "json_schemer" do
    url "https://rubygems.org/downloads/json_schemer-2.5.0.gem"
    sha256 "2f01fb4cce721a4e08dd068fc2030cffd0702a7f333f1ea2be6e8991f00ae396"
  end

  resource "logger" do
    url "https://rubygems.org/downloads/logger-1.7.0.gem"
    sha256 "196edec7cc44b66cfb40f9755ce11b392f21f7967696af15d274dde7edff0203"
  end

  resource "mcp" do
    url "https://rubygems.org/downloads/mcp-0.20.0.gem"
    sha256 "6b71bfc9a19f6dca34953bded1bd89cba75176a4f8bb293ce82ace065af584f9"
  end

  resource "psych" do
    url "https://rubygems.org/downloads/psych-5.3.1.gem"
    sha256 "eb7a57cef10c9d70173ff74e739d843ac3b2c019a003de48447b2963d81b1974"
  end

  resource "regexp_parser" do
    url "https://rubygems.org/downloads/regexp_parser-2.12.0.gem"
    sha256 "35a916a1d63190ab5c9009457136ae5f3c0c7512d60291d0d1378ba18ce08ebb"
  end

  resource "rexml" do
    url "https://rubygems.org/downloads/rexml-3.4.4.gem"
    sha256 "19e0a2c3425dfbf2d4fc1189747bdb2f849b6c5e74180401b15734bc97b5d142"
  end

  resource "simpleidn" do
    url "https://rubygems.org/downloads/simpleidn-0.2.3.gem"
    sha256 "08ce96f03fa1605286be22651ba0fc9c0b2d6272c9b27a260bc88be05b0d2c29"
  end

  resource "sqlite3" do
    url "https://rubygems.org/downloads/sqlite3-2.9.5-arm64-darwin.gem"
    sha256 "d0cf444a70fc9395d513cfbcc1e6719e224aa645314e3824cb0474c721425aa2"
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
