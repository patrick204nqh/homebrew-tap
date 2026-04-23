# frozen_string_literal: true

class Browserctl < Formula
  desc "Persistent browser automation daemon and CLI for AI agents"
  homepage "https://github.com/patrick204nqh/browserctl"
  url "https://github.com/patrick204nqh/browserctl/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "c42ba1dac906b71e8f58c4b3c0ac0d3e90cf48111bd5136d54bc951b37f24b5f"
  license "MIT"

  depends_on "gmp"

  # Bundled Ruby runtime — built by .github/workflows/build-ruby-runtime.yml.
  # Avoids depending on homebrew-core's `ruby` (which pulls in llvm) so bottles
  # work on any Homebrew prefix without source compilation.
  #
  # To update: run the build-ruby-runtime workflow for the desired version, then
  # replace the sha256 values below with the ones printed in the workflow summary.
  RUBY_RUNTIME_VERSION = "3.3.6"

  resource "ruby-runtime" do
    url "https://github.com/patrick204nqh/homebrew-tap/releases/download/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}/" \
        "ruby-runtime-#{RUBY_RUNTIME_VERSION}-arm64-darwin.tar.gz"
    sha256 "83ad276e1f9df812893dca46701c88b2713cd15698f3b353a9c355cdf25470fd"
  end

  # nokogiri — precompiled arm64 platform gem (avoids needing libxml2/libxslt)
  resource "nokogiri" do
    url "https://rubygems.org/downloads/nokogiri-1.19.2-arm64-darwin.gem"
    sha256 "58d8ea2e31a967b843b70487a44c14c8ba1866daa1b9da9be9dbdf1b43dee205"
  end

  # ferrum and its transitive deps
  resource "ferrum" do
    url "https://rubygems.org/downloads/ferrum-0.17.2.gem"
    sha256 "2c2540a850b211a46f4d81de21bfd62048f507e4c327d1807225c3823c17e6ee"
  end

  resource "addressable" do
    url "https://rubygems.org/downloads/addressable-2.9.0.gem"
    sha256 "7fdf6ac3660f7f4e867a0838be3f6cf722ace541dd97767fa42bc6cfa980c7af"
  end

  resource "public_suffix" do
    url "https://rubygems.org/downloads/public_suffix-7.0.5.gem"
    sha256 "1a8bb08f1bbea19228d3bed6e5ed908d1cb4f7c2726d18bd9cadf60bc676f623"
  end

  resource "base64" do
    url "https://rubygems.org/downloads/base64-0.3.0.gem"
    sha256 "27337aeabad6ffae05c265c450490628ef3ebd4b67be58257393227588f5a97b"
  end

  resource "concurrent-ruby" do
    url "https://rubygems.org/downloads/concurrent-ruby-1.3.6.gem"
    sha256 "6b56837e1e7e5292f9864f34b69c5a2cbc75c0cf5338f1ce9903d10fa762d5ab"
  end

  resource "webrick" do
    url "https://rubygems.org/downloads/webrick-1.9.2.gem"
    sha256 "beb4a15fc474defed24a3bda4ffd88a490d517c9e4e6118c3edce59e45864131"
  end

  resource "websocket-driver" do
    url "https://rubygems.org/downloads/websocket-driver-0.8.0.gem"
    sha256 "ed0dba4b943c22f17f9a734817e808bc84cdce6a7e22045f5315aa57676d4962"
  end

  resource "websocket-extensions" do
    url "https://rubygems.org/downloads/websocket-extensions-0.1.5.gem"
    sha256 "1c6ba63092cda343eb53fc657110c71c754c56484aad42578495227d717a8241"
  end

  resource "optimist" do
    url "https://rubygems.org/downloads/optimist-3.2.1.gem"
    sha256 "8cf8a0fd69f3aa24ab48885d3a666717c27bc3d9edd6e976e18b9d771e72e34e"
  end

  def install
    ruby_runtime = libexec / "ruby-runtime"
    resource("ruby-runtime").stage { ruby_runtime.install Dir["*"] }

    bundled_ruby = ruby_runtime / "bin/ruby"
    bundled_gem  = ruby_runtime / "bin/gem"
    gem_home     = libexec / "gems"

    # Relocate the runtime to this Cellar path (fix dylib load path + shebangs).
    # Tarballs built by the current workflow bundle relocate-runtime.sh; the
    # inline fallback handles runtimes built before the script was introduced.
    if (ruby_runtime / "relocate-runtime.sh").exist?
      system "bash", ruby_runtime / "relocate-runtime.sh", ruby_runtime
    else
      old_dylib = Utils.safe_popen_read("otool", "-L", bundled_ruby.to_s).lines
        .map { |l| l.strip.split.first }
        .find { |p| p =~ /libruby\.\d+\.\d+\.dylib$/ }
      if old_dylib && !old_dylib.start_with?("@")
        system "install_name_tool", "-change", old_dylib,
               "@loader_path/../lib/#{File.basename(old_dylib)}", bundled_ruby
      end
      Pathname.glob("#{ruby_runtime}/bin/*").each do |f|
        next if f.symlink? || !f.file?
        content = f.read
        next unless content.match?(/\A#!.*ruby/)
        f.write content.sub(/\A#!.*/, "#!#{bundled_ruby}")
      end
    end

    ENV["GEM_HOME"] = gem_home

    (resources - [resource("ruby-runtime")]).each do |r|
      r.stage do
        system bundled_gem, "install", r.cached_download,
               "--no-document", "--ignore-dependencies", "--install-dir", gem_home
      end
    end

    libexec.install "lib"
    (libexec / "bin").install "bin/browserctl", "bin/browserd"

    ruby_version = Utils.safe_popen_read(
      bundled_ruby, "-e", "puts RbConfig::CONFIG['ruby_version']"
    ).chomp
    ruby_stdlib_gems = ruby_runtime / "lib/ruby/gems" / ruby_version

    env = {
      GEM_HOME: gem_home,
      GEM_PATH: "#{gem_home}#{File::PATH_SEPARATOR}#{ruby_stdlib_gems}",
      PATH:     "#{ruby_runtime / "bin"}#{File::PATH_SEPARATOR}#{ENV.fetch("PATH", nil)}",
    }
    (bin / "browserctl").write_env_script(libexec / "bin/browserctl", env)
    (bin / "browserd").write_env_script(libexec / "bin/browserd", env)
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
      browserctl requires Google Chrome or Chromium to be installed.

      Start the browser daemon:
        browserd

      Then control the browser:
        browserctl goto https://example.com
        browserctl snap
        browserctl screenshot

      Stop the daemon:
        browserctl shutdown
    EOS
  end

  test do
    assert_match "Usage: browserctl", shell_output("#{bin}/browserctl --help 2>&1")
  end
end
