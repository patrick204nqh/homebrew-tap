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
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0f20c77faf2cf5e9788c2aa0aefe1fb461335435c45932f080f5c17ee46c6033"
  end

  depends_on "ruby"

  resource "thor" do
    url "https://rubygems.org/downloads/thor-1.3.2.gem"
    sha256 "eef0293b9e24158ccad7ab383ae83534b7ad4ed99c09f96f1a6b036550abbeda"
  end

  resource "base64" do
    url "https://rubygems.org/downloads/base64-0.2.0.gem"
    sha256 "0f25e9b21a02a0cc0cea8ef92b2041035d39350946e8789c562b2d1a3da01507"
  end

  def install
    ENV["GEM_HOME"] = libexec
    resources.each do |r|
      r.fetch
      system "gem", "install", r.cached_download,
             "--no-document", "--ignore-dependencies", "--install-dir", libexec
    end

    # Preserve lib/ so the bin script can resolve ../lib relative to its location
    libexec.install "lib"
    (libexec / "bin").install "bin/sumo-query"

    # Pin shebang to Homebrew's Ruby so native gem extensions are ABI-compatible
    inreplace libexec / "bin/sumo-query", /\A#!.*/, "#!#{Formula["ruby"].opt_bin}/ruby"

    (bin / "sumo-query").write_env_script(libexec / "bin/sumo-query", GEM_HOME: libexec, GEM_PATH: libexec)
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
end
