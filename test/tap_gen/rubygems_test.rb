# frozen_string_literal: true

require "test_helper"
require "tap_gen/rubygems"
require "tap_gen/gem_resource"

class RubygemsTest < Minitest::Test
  def setup
    skip "set TAP_GEN_NETWORK=1 to run network tests" unless ENV["TAP_GEN_NETWORK"]
  end

  def test_pure_ruby_gem_returns_resource_without_platform
    r = TapGen::Rubygems.resolve("thor", "1.5.0")
    assert_nil r.platform
    assert_equal "thor", r.name
    assert_equal "1.5.0", r.version
    assert_match(/\A[a-f0-9]{64}\z/, r.sha256)
  end

  def test_native_gem_prefers_arm64_darwin_platform
    r = TapGen::Rubygems.resolve("nokogiri", "1.19.3")
    assert_equal "arm64-darwin", r.platform
    assert_match(/\A[a-f0-9]{64}\z/, r.sha256)
  end
end
