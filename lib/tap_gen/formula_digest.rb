# frozen_string_literal: true

require "digest"

module TapGen
  # Computes a digest of a formula's install-relevant content — the whole file
  # minus the `bottle do … end` block and minus the `# bottle-source-digest:`
  # line itself. `bottle.yml` compares this against the stamped value to decide
  # whether a bottle must be rebuilt: it is stable across the bot's bottle-block
  # rewrite (so the commit-back loop short-circuits) but changes whenever gem
  # resources or the source version change.
  module FormulaDigest
    class NoBottleBlock < StandardError; end

    DIGEST_RE = /^[ \t]*# bottle-source-digest: [a-f0-9]{64}\n/
    # The bottle block has no nested do…end, so the non-greedy match is safe.
    BOTTLE_RE = /^[ \t]*bottle do\b.*?^[ \t]*end[ \t]*\n/m

    module_function

    def compute(text)
      stripped = text.sub(DIGEST_RE, "").sub(BOTTLE_RE, "")
      Digest::SHA256.hexdigest(stripped)
    end

    # Returns `text` with a fresh `# bottle-source-digest:` line directly above
    # the `bottle do` block (replacing any existing one). Idempotent.
    def stamp(text)
      digest = compute(text)
      without = text.sub(DIGEST_RE, "")
      raise NoBottleBlock, "no `bottle do` block to stamp" unless without =~ /^([ \t]*)bottle do\b/

      without.sub(/^([ \t]*)bottle do\b/) do
        indent = Regexp.last_match(1)
        "#{indent}# bottle-source-digest: #{digest}\n#{indent}bottle do"
      end
    end
  end
end
