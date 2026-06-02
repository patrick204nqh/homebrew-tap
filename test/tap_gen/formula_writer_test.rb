# frozen_string_literal: true

require "test_helper"
require "tap_gen/gem_resource"
require "tap_gen/formula_writer"

class FormulaWriterTest < Minitest::Test
  SHA = "a" * 64

  def resources
    [
      TapGen::GemResource.new(name: "base64", version: "0.3.0", sha256: SHA),
      TapGen::GemResource.new(name: "thor", version: "1.5.0", sha256: SHA),
    ]
  end

  # A formula with a multi-line ruby-runtime resource (must be preserved) and
  # two single-line rubygems resources (must be replaced).
  def first_run_formula
    <<~RUBY
      class Example < Formula
        resource "ruby-runtime" do
          url "https://example.com/runtime/" \\
              "ruby-runtime.tar.gz"
          sha256 "#{SHA}"
        end

        resource "thor" do
          url "https://rubygems.org/downloads/thor-1.0.0.gem"
          sha256 "#{SHA}"
        end

        resource "base64" do
          url "https://rubygems.org/downloads/base64-0.1.0.gem"
          sha256 "#{SHA}"
        end

        def install
          true
        end
      end
    RUBY
  end

  def test_first_run_inserts_markers_and_replaces_rubygems_blocks
    out = TapGen::FormulaWriter.replace_gem_section(first_run_formula, resources)

    assert_includes out, TapGen::FormulaWriter::BEGIN_MARKER
    assert_includes out, TapGen::FormulaWriter::END_MARKER
    assert_includes out, %(resource "ruby-runtime" do)
    assert_includes out, %("https://example.com/runtime/" \\)
    assert_includes out, "https://rubygems.org/downloads/base64-0.3.0.gem"
    assert_includes out, "https://rubygems.org/downloads/thor-1.5.0.gem"
    refute_includes out, "thor-1.0.0.gem"
    refute_includes out, "base64-0.1.0.gem"
    assert_includes out, "def install"
    # Resources render in the order given (base64 before thor).
    assert out.index("base64-0.3.0.gem") < out.index("thor-1.5.0.gem"),
           "expected resources to render in given order"
  end

  def test_second_run_replaces_between_existing_markers
    once = TapGen::FormulaWriter.replace_gem_section(first_run_formula, resources)
    newer = [TapGen::GemResource.new(name: "thor", version: "1.6.0", sha256: SHA)]
    twice = TapGen::FormulaWriter.replace_gem_section(once, newer)

    assert_equal 1, twice.scan(TapGen::FormulaWriter::BEGIN_MARKER).size
    assert_includes twice, "thor-1.6.0.gem"
    refute_includes twice, "thor-1.5.0.gem"
    refute_includes twice, "base64-0.3.0.gem"
    assert_includes twice, %(resource "ruby-runtime" do)
  end

  def test_raises_when_no_gem_resources_present
    src = "class Empty < Formula\n  def install; end\nend\n"
    assert_raises(TapGen::FormulaWriter::NoGemSection) do
      TapGen::FormulaWriter.replace_gem_section(src, resources)
    end
  end
end
