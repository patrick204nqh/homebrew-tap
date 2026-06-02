# frozen_string_literal: true

module TapGen
  # One bundled gem, rendered as a Homebrew `resource` block.
  # `platform` is nil for pure-Ruby gems, or e.g. "arm64-darwin" for a
  # precompiled platform gem.
  class GemResource
    attr_reader :name, :version, :sha256, :platform

    def initialize(name:, version:, sha256:, platform: nil)
      @name = name
      @version = version
      @sha256 = sha256
      @platform = platform
    end

    def filename
      stem = [name, version, platform].compact.join("-")
      "#{stem}.gem"
    end

    def url
      "https://rubygems.org/downloads/#{filename}"
    end

    def to_block(indent: 2)
      pad = " " * indent
      inner = " " * (indent + 2)
      [
        %(#{pad}resource "#{name}" do),
        %(#{inner}url "#{url}"),
        %(#{inner}sha256 "#{sha256}"),
        %(#{pad}end),
      ].join("\n")
    end
  end
end
