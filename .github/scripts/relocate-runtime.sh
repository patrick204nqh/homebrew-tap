#!/usr/bin/env bash
# relocate-runtime.sh — finalises the ruby-runtime for its installed location.
#
# Usage: bash relocate-runtime.sh <runtime-prefix>
#   runtime-prefix  Absolute path to the ruby-runtime directory (e.g.
#                   /opt/homebrew/Cellar/browserctl/1.0.0/libexec/ruby-runtime)
#
# Called by Homebrew formulas immediately after staging the ruby-runtime
# resource into its Cellar location.  Safe to run multiple times (idempotent).
#
# What it does
# ────────────
# 1. Dylib load path — repairs the ruby binary's libruby reference if it is
#    still an absolute path from the build environment.  Runtimes produced by
#    the current workflow already emit @loader_path, so this is a no-op.
# 2. Script shebangs — replaces any ruby shebang (absolute build path OR the
#    portable #!/usr/bin/env ruby placeholder) with the exact installed path so
#    gem, irb, erb, … all invoke the bundled interpreter.
set -euo pipefail

PREFIX="${1:?Usage: $(basename "$0") <runtime-prefix>}"
RUBY_BIN="$PREFIX/bin/ruby"

# ── 1. Dylib load path ──────────────────────────────────────────────────────
old_dylib=$(otool -L "$RUBY_BIN" 2>/dev/null \
  | awk '/libruby\.[0-9]+\.[0-9]+\.dylib/ { print $1 }')
if [[ -n "$old_dylib" && "$old_dylib" != @* ]]; then
  lib_name=$(basename "$old_dylib")
  install_name_tool -change "$old_dylib" \
    "@loader_path/../lib/$lib_name" "$RUBY_BIN"
fi

# ── 2. Script shebangs ──────────────────────────────────────────────────────
find "$PREFIX/bin" -maxdepth 1 -type f | while IFS= read -r f; do
  head -c 2 "$f" | grep -q '^#!' || continue
  head -1 "$f" | grep -q 'ruby'  || continue
  sed -i '' "1s|^#!.*|#!${RUBY_BIN}|" "$f"
done
