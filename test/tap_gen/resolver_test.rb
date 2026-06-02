# frozen_string_literal: true

require "test_helper"
require "tap_gen/resolver"

class ResolverTest < Minitest::Test
  def fixture(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end

  def test_returns_only_default_group_runtime_gems
    gems = TapGen::Resolver.runtime_gems(fixture("sample_project"))
    # thor is a runtime dep; sample (self) and minitest (dev) are excluded.
    assert_equal [["thor", "1.5.0"]], gems
  end

  def test_excludes_dev_tools_listed_in_the_default_group
    # flat/Gemfile lists `gem "rake"` outside any group block (so Bundler
    # puts rake in :default). rake is not a runtime dep of the project gem,
    # so it must NOT appear — this is the bug that `specs_for([:default])`
    # alone would miss.
    gems = TapGen::Resolver.runtime_gems(fixture("flat_project"))
    assert_equal [["thor", "1.5.0"]], gems
  end

  def test_includes_transitive_runtime_deps_across_multiple_hops
    # deep → mid → leaf. The grandchild (leaf) must be in the closure.
    gems = TapGen::Resolver.runtime_gems(fixture("deep_project"))
    assert_equal [["leaf", "2.0.0"], ["mid", "1.0.0"]], gems
  end
end
