# frozen_string_literal: true

module TapGen
  # Splices a generated gem-resource section into a formula's source text.
  # Only single-line rubygems.org resource blocks are managed; the multi-line
  # `resource "ruby-runtime"` block (whose url spans lines with `\`) never
  # matches RESOURCE_RE and is therefore preserved untouched.
  module FormulaWriter
    class NoGemSection < StandardError; end

    BEGIN_MARKER =
      "  # ── BEGIN generated gem resources — managed by script/gen-formula, do not edit ──"
    END_MARKER = "  # ── END generated gem resources ──"

    # Matches one single-line rubygems resource block, including its trailing
    # newline. Mirrors .github/scripts/sync-gems.rb.
    RESOURCE_RE = %r{
      ^([ \t]*)resource\ "[^"]+"\ do\n
      [ \t]*url\ "https://rubygems\.org/downloads/[^"]+\.gem"\n
      [ \t]*sha256\ "[a-f0-9]{64}"\n
      [ \t]*end[ \t]*\n
    }x

    # Renders the marked gem section. Resources are emitted in the order given.
    # An empty `resources` list is legal — it produces empty markers, which
    # clears the managed section (correct for a tool with no runtime gems).
    def self.render_section(resources)
      body = resources.map { |r| r.to_block(indent: 2) }.join("\n\n")
      "#{BEGIN_MARKER}\n#{body}\n#{END_MARKER}\n"
    end

    def self.replace_gem_section(text, resources)
      section = render_section(resources)

      if text.include?(BEGIN_MARKER)
        re = /#{Regexp.escape(BEGIN_MARKER)}.*?#{Regexp.escape(END_MARKER)}\n/m
        return text.sub(re, section)
      end

      matches = []
      text.scan(RESOURCE_RE) { matches << Regexp.last_match }
      raise NoGemSection, "no rubygems.org resource blocks found — cannot determine splice point" if matches.empty?

      # Replace the whole span from the first to the last rubygems resource
      # block — this drops any explanatory comments and blank lines woven
      # between them (they describe gems and are superseded by the generated
      # section). Also absorb a run of gem-annotation comment/blank lines
      # immediately preceding the first block. The result is normalised to one
      # blank line on each side of the generated section.
      before = text[0...matches.first.begin(0)].sub(/(?:[ \t]*#[^\n]*\n|[ \t]*\n)+\z/, "")
      after  = text[matches.last.end(0)..].sub(/\A\n+/, "")

      "#{before.rstrip}\n\n#{section}\n#{after}"
    end
  end
end
