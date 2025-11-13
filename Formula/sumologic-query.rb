# frozen_string_literal: true

class SumologicQuery < Formula
  desc 'Lightweight Ruby CLI for querying Sumo Logic logs quickly'
  homepage 'https://github.com/patrick204nqh/sumologic-query'
  url 'https://github.com/patrick204nqh/sumologic-query/archive/refs/tags/v1.1.0.tar.gz'
  sha256 '4cb6e2f1377da0d917618ac9dc32db0f2c87452c2270878802f6dd1ccc56dd7c'
  license 'MIT'

  # No dependencies! Uses macOS system Ruby (comes with macOS)
  # This makes installation instant - no building required

  def install
    # Install library files
    libexec.install Dir['lib/*']

    # Create standalone executable that uses system Ruby
    (bin / 'sumo-query').write <<~EOS
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      $LOAD_PATH.unshift('#{libexec}')
      load '#{libexec}/../bin/sumo-query'
    EOS

    # Install the actual CLI script
    libexec.install 'bin/sumo-query'
  end

  test do
    # Test that the binary exists and shows version
    assert_match "sumologic-query v#{version}", shell_output("#{bin}/sumo-query --version")
  end

  def caveats
    <<~EOS
      This formula requires Ruby 2.7 or later.
      macOS Catalina (10.15) and later include Ruby 2.6, so you may need to:
        - Install Ruby via Homebrew: brew install ruby
        - Or use a Ruby version manager (rbenv, asdf, etc.)

      To verify your Ruby version:
        ruby --version
    EOS
  end
end
