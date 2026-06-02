# frozen_string_literal: true

require "test_helper"
require "tap_gen/formula_digest"

class FormulaDigestTest < Minitest::Test
  def formula(bottle_sha:, gem_version:, digest_line: nil)
    <<~RUBY
      class Example < Formula
        url "https://example.com/v1.2.3.tar.gz"
        sha256 "#{"s" * 64}"
      #{"  # bottle-source-digest: #{digest_line}\n" if digest_line}  bottle do
          root_url "https://example.com/releases/download/example-v1.2.3"
          sha256 cellar: :any, arm64_sequoia: "#{bottle_sha}"
        end

        resource "thor" do
          url "https://rubygems.org/downloads/thor-#{gem_version}.gem"
          sha256 "#{"a" * 64}"
        end
      end
    RUBY
  end

  def test_digest_is_stable_when_only_the_bottle_sha_changes
    a = TapGen::FormulaDigest.compute(formula(bottle_sha: "b" * 64, gem_version: "1.5.0"))
    b = TapGen::FormulaDigest.compute(formula(bottle_sha: "c" * 64, gem_version: "1.5.0"))
    assert_equal a, b, "bottle-block contents must not affect the digest"
  end

  def test_digest_changes_when_a_gem_version_changes
    a = TapGen::FormulaDigest.compute(formula(bottle_sha: "b" * 64, gem_version: "1.5.0"))
    b = TapGen::FormulaDigest.compute(formula(bottle_sha: "b" * 64, gem_version: "1.6.0"))
    refute_equal a, b, "a gem-resource change must change the digest"
  end

  def test_digest_ignores_an_existing_digest_line
    without = TapGen::FormulaDigest.compute(formula(bottle_sha: "b" * 64, gem_version: "1.5.0"))
    with    = TapGen::FormulaDigest.compute(
      formula(bottle_sha: "b" * 64, gem_version: "1.5.0", digest_line: "f" * 64)
    )
    assert_equal without, with, "the digest line itself must not affect the digest"
  end

  def test_stamp_inserts_digest_line_above_bottle_and_is_idempotent
    src = formula(bottle_sha: "b" * 64, gem_version: "1.5.0")
    once = TapGen::FormulaDigest.stamp(src)
    twice = TapGen::FormulaDigest.stamp(once)

    assert_equal once, twice, "stamping twice must be a no-op"
    assert_equal 1, once.scan("# bottle-source-digest:").size
    # The stamped digest matches what compute() reports for the file.
    stored = once[/# bottle-source-digest: ([a-f0-9]{64})/, 1]
    assert_equal TapGen::FormulaDigest.compute(once), stored
    # The line sits immediately above `bottle do`.
    assert_match(/# bottle-source-digest: [a-f0-9]{64}\n[ \t]*bottle do/, once)
  end

  def test_stamp_raises_without_a_bottle_block
    assert_raises(TapGen::FormulaDigest::NoBottleBlock) do
      TapGen::FormulaDigest.stamp("class X < Formula\n  url \"u\"\nend\n")
    end
  end
end
