# frozen_string_literal: true

class SumologicQuery < Formula
  desc "Lightweight Ruby CLI for querying Sumo Logic logs quickly"
  homepage "https://github.com/patrick204nqh/sumologic-query"
  url "https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "4282fc7daa74ffd3a4d37bf87447b1282cd3ec7ee4217f63bd17a84592610620"
  license "MIT"

  # Minimal dependencies - uses system Ruby (macOS includes Ruby 2.6+)
  # On Linux, Homebrew will install Ruby if not present
  uses_from_macos "ruby", since: :catalina

  resource "thor" do
    url "https://rubygems.org/downloads/thor-1.3.2.gem"
    sha256 "eef0293b9e24158ccad7ab383ae83534b7ad4ed99c09f96f1a6b036550abbeda"
  end

  resource "base64" do
    url "https://rubygems.org/downloads/base64-0.2.0.gem"
    sha256 "0f25e9b21a02a0cc0cea8ef92b2041035d39350946e8789c562b2d1a3da01507"
  end

  def install
    # Install gem dependencies to libexec
    ENV["GEM_HOME"] = libexec
    resources.each do |r|
      r.fetch
      system "gem", "install", r.cached_download, "--no-document", "--install-dir", libexec
    end

    # Install library files and binary
    libexec.install Dir["lib/*"]
    (libexec / "bin").mkpath
    (libexec / "bin").install "bin/sumo-query"

    # Create wrapper script that sets up GEM_HOME and loads dependencies
    (bin / "sumo-query").write_env_script(libexec / "bin/sumo-query", GEM_HOME: libexec, GEM_PATH: libexec)
  end

  test do
    # Test that the binary exists and shows help
    assert_match "Commands:", shell_output("#{bin}/sumo-query help")
    assert_match "search", shell_output("#{bin}/sumo-query help")
    assert_match "list-collectors", shell_output("#{bin}/sumo-query help")
    assert_match "list-sources", shell_output("#{bin}/sumo-query help")
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
end
