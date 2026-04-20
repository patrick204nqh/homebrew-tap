# frozen_string_literal: true

class Browserctl < Formula
  desc "Persistent browser automation daemon and CLI for AI agents"
  homepage "https://github.com/patrick204nqh/browserctl"
  url "https://github.com/patrick204nqh/browserctl/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "57299ed461765fad7f2d0287a83c1fc0c947f1b96932266651bbe68c6818d89e"
  license "MIT"

  bottle do
    root_url "https://github.com/patrick204nqh/homebrew-tap/releases/download/browserctl-0.2.1"
    rebuild 2
    sha256 cellar: :any, arm64_sequoia: "d77bf61598f7d8155450739098ce640ec84cb502546581a96893e110817304e8"
  end

  depends_on "ruby"

  # nokogiri — precompiled platform gems (avoids needing libxml2/libxslt)
  resource "nokogiri" do
    on_arm do
      url "https://rubygems.org/downloads/nokogiri-1.19.2-arm64-darwin.gem"
      sha256 "58d8ea2e31a967b843b70487a44c14c8ba1866daa1b9da9be9dbdf1b43dee205"
    end
    on_intel do
      url "https://rubygems.org/downloads/nokogiri-1.19.2-x86_64-darwin.gem"
      sha256 "7d9af11fda72dfaa2961d8c4d5380ca0b51bc389dc5f8d4b859b9644f195e7a4"
    end
  end

  resource "racc" do
    url "https://rubygems.org/downloads/racc-1.8.1.gem"
    sha256 "4a7f6929691dbec8b5209a0b373bc2614882b55fc5d2e447a21aaa691303d62f"
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
    ENV["GEM_HOME"] = libexec
    resources.each do |r|
      r.fetch
      system "gem", "install", r.cached_download,
             "--no-document", "--ignore-dependencies", "--install-dir", libexec
    end

    # Preserve lib/ so the bin scripts can resolve ../lib relative to their location
    libexec.install "lib"
    (libexec / "bin").install "bin/browserctl", "bin/browserd"

    # Pin shebang to Homebrew's Ruby so native gem extensions are ABI-compatible
    ruby = Formula["ruby"].opt_bin / "ruby"
    inreplace libexec / "bin/browserctl", /\A#!.*/, "#!#{ruby}"
    inreplace libexec / "bin/browserd", /\A#!.*/, "#!#{ruby}"

    env = { GEM_HOME: libexec, GEM_PATH: libexec }
    (bin / "browserctl").write_env_script(libexec / "bin/browserctl", env)
    (bin / "browserd").write_env_script(libexec / "bin/browserd", env)
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
