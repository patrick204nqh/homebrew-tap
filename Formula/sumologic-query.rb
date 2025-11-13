# frozen_string_literal: true

class SumologicQuery < Formula
  desc 'Lightweight Ruby CLI for querying Sumo Logic logs quickly'
  homepage 'https://github.com/patrick204nqh/sumologic-query'
  url 'https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.1.0.tar.gz'
  sha256 '4cb6e2f1377da0d917618ac9dc32db0f2c87452c2270878802f6dd1ccc56dd7c' # Will be calculated after first release
  license 'MIT'

  # Use system Ruby instead of building from source (much faster!)
  uses_from_macos 'ruby', since: :catalina

  def install
    ENV['GEM_HOME'] = libexec

    # Build and install gem with system Ruby
    system 'gem', 'build', 'sumologic-query.gemspec'
    system 'gem', 'install', '--no-document', "sumologic-query-#{version}.gem"

    # Create wrapper script with proper gem paths
    (bin / 'sumo-query').write_env_script(
      libexec / 'bin/sumo-query',
      GEM_HOME: libexec,
      GEM_PATH: libexec
    )
  end

  test do
    # Test that the binary exists and shows version
    assert_match "sumologic-query v#{version}", shell_output("#{bin}/sumo-query --version")
  end
end
