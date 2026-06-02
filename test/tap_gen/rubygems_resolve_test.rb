# frozen_string_literal: true

require "test_helper"
require "digest"
require "tap_gen/rubygems"
require "tap_gen/gem_resource"

# Unit tests for resolve's selection logic — no network. Unlike the gated
# integration tests in rubygems_test.rb, these run in CI: they inject a fake
# fetcher so the platform-preference, fallback, and error paths are covered.
class RubygemsResolveTest < Minitest::Test
  def test_prefers_platform_gem_when_available
    fetcher = ->(url) { url.include?("arm64-darwin") ? "platform-bytes" : nil }
    r = TapGen::Rubygems.resolve("mygem", "1.0.0", fetcher: fetcher)
    assert_equal "arm64-darwin", r.platform
    assert_equal Digest::SHA256.hexdigest("platform-bytes"), r.sha256
  end

  def test_falls_back_to_pure_gem_when_platform_absent
    fetcher = ->(url) { url.include?("arm64-darwin") ? nil : "pure-bytes" }
    r = TapGen::Rubygems.resolve("mygem", "1.0.0", fetcher: fetcher)
    assert_nil r.platform
    assert_equal Digest::SHA256.hexdigest("pure-bytes"), r.sha256
  end

  def test_raises_when_neither_download_exists
    fetcher = ->(_url) { nil } # rubocop:disable Style/NilLambda
    assert_raises(RuntimeError) { TapGen::Rubygems.resolve("mygem", "1.0.0", fetcher: fetcher) }
  end
end
