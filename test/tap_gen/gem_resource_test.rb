# frozen_string_literal: true

require "test_helper"
require "tap_gen/gem_resource"

class GemResourceTest < Minitest::Test
  def test_pure_ruby_filename_and_url
    r = TapGen::GemResource.new(name: "thor", version: "1.5.0", sha256: "abc")
    assert_equal "thor-1.5.0.gem", r.filename
    assert_equal "https://rubygems.org/downloads/thor-1.5.0.gem", r.url
  end

  def test_platform_filename_and_url
    r = TapGen::GemResource.new(
      name: "nokogiri", version: "1.19.3", sha256: "abc", platform: "arm64-darwin"
    )
    assert_equal "nokogiri-1.19.3-arm64-darwin.gem", r.filename
    assert_equal "https://rubygems.org/downloads/nokogiri-1.19.3-arm64-darwin.gem", r.url
  end

  def test_to_block_renders_two_space_indented_resource
    r = TapGen::GemResource.new(
      name: "base64", version: "0.3.0",
      sha256: "27337aeabad6ffae05c265c450490628ef3ebd4b67be58257393227588f5a97b"
    )
    # rubocop:disable Lint/LiteralInInterpolation
    expected = <<~BLOCK.chomp
      #{"  "}resource "base64" do
      #{"    "}url "https://rubygems.org/downloads/base64-0.3.0.gem"
      #{"    "}sha256 "27337aeabad6ffae05c265c450490628ef3ebd4b67be58257393227588f5a97b"
      #{"  "}end
    BLOCK
    # rubocop:enable Lint/LiteralInInterpolation
    assert_equal expected, r.to_block(indent: 2)
  end
end
