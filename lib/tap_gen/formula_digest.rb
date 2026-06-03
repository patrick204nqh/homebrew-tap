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
      stripped = normalize(text).sub(DIGEST_RE, "").sub(BOTTLE_RE, "")
      Digest::SHA256.hexdigest(stripped)
    end

    # Returns `text` with a fresh `# bottle-source-digest:` line directly above
    # the `bottle do` block (replacing any existing one). Idempotent.
    #
    # Also collapses runs of blank lines to a single one. `brew bottle --write`
    # re-inserts the bottle block on top of the blank line left by the previous
    # block's removal, producing a double blank that `brew style` rejects.
    # Normalizing here — the last write before commit-back — keeps every bot
    # bottle commit lint-clean and the stamped digest consistent with the file.
    def stamp(text)
      normalized = normalize(text)
      digest = compute(normalized)
      without = normalized.sub(DIGEST_RE, "")
      raise NoBottleBlock, "no `bottle do` block to stamp" unless without =~ /^([ \t]*)bottle do\b/

      without.sub(/^([ \t]*)bottle do\b/) do
        indent = Regexp.last_match(1)
        "#{indent}# bottle-source-digest: #{digest}\n#{indent}bottle do"
      end
    end

    # Collapse 2+ consecutive blank lines to one. No-op on lint-clean formulas,
    # so existing stamped digests are unaffected.
    def normalize(text)
      text.gsub(/\n{3,}/, "\n\n")
    end
  end
end
