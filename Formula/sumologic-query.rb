# frozen_string_literal: true

class SumologicQuery < Formula
  desc 'Lightweight Ruby CLI for querying Sumo Logic logs quickly'
  homepage 'https://github.com/patrick204nqh/sumologic-query'
  url 'https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.0.0.tar.gz'
  sha256 '' # Will be calculated after first release
  license 'MIT'

  depends_on 'ruby' => :build

  def install
    ENV['GEM_HOME'] = libexec
    system 'gem', 'build', 'sumologic-query.gemspec'
    system 'gem', 'install', "sumologic-query-#{version}.gem"
    bin.install libexec / 'bin/sumo-query'
    bin.env_script_all_files(libexec / 'bin', GEM_HOME: ENV.fetch('GEM_HOME', nil))
  end

  test do
    # Test that the binary exists and shows version
    assert_match "sumologic-query v#{version}", shell_output("#{bin}/sumo-query --version")
  end
end
