# frozen_string_literal: true

class SumologicQuery < Formula
  desc 'Lightweight Ruby CLI for querying Sumo Logic logs quickly'
  homepage 'https://github.com/patrick204nqh/sumologic-query'
  url 'https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.1.1.tar.gz'
  sha256 'b88b90a69a69296bf72d26c0ccfa1e5bad7d661b02fa677243147da2ef4d5bd6'
  license 'MIT'

  # Minimal dependencies - uses system Ruby with thor gem for CLI
  depends_on 'ruby' => :build

  resource 'thor' do
    url 'https://rubygems.org/downloads/thor-1.3.2.gem'
    sha256 'eef0293b9e24158ccad7ab383ae83534b7ad4ed99c09f96f1a6b036550abbeda'
  end

  resource 'base64' do
    url 'https://rubygems.org/downloads/base64-0.2.0.gem'
    sha256 'b39751615e51a5c8c5e1a7e73d9e8fc7e68c7ba23d2c4a63f4ec2e56c6a3c1f4'
  end

  def install
    # Install gem dependencies to libexec
    ENV['GEM_HOME'] = libexec
    resources.each do |r|
      r.fetch
      system 'gem', 'install', r.cached_download, '--no-document', '--install-dir', libexec
    end

    # Install library files
    libexec.install Dir['lib/*']
    libexec.install 'bin/sumo-query'

    # Create wrapper script that sets up GEM_HOME and loads dependencies
    (bin / 'sumo-query').write_env_script(libexec / 'bin/sumo-query', GEM_HOME: libexec, GEM_PATH: libexec)
  end

  test do
    # Test that the binary exists and shows help
    assert_match 'Commands:', shell_output("#{bin}/sumo-query help")
    assert_match 'search', shell_output("#{bin}/sumo-query help")
    assert_match 'list-collectors', shell_output("#{bin}/sumo-query help")
    assert_match 'list-sources', shell_output("#{bin}/sumo-query help")
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
