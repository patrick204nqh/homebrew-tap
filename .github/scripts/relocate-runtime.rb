#!/usr/bin/env ruby
# frozen_string_literal: true

# relocate-runtime.rb — finalises the ruby-runtime for its installed location.
#
# Usage: ruby relocate-runtime.rb <runtime-prefix>
#   runtime-prefix  Absolute path to the ruby-runtime directory (e.g.
#                   /opt/homebrew/Cellar/browserctl/1.0.0/libexec/ruby-runtime)
#
# Called by Homebrew formulas immediately after staging the ruby-runtime
# resource into its Cellar location.  Safe to run multiple times (idempotent).
#
# What it does
# ────────────
# 1. rbconfig.rb   — corrects the build-time prefix calculation so RbConfig
#                    paths resolve relative to the installed location.
# 2. Dylib load path — repairs the ruby binary's libruby reference if it is
#                    still an absolute path from the build environment.
# 3. Script shebangs — replaces any ruby shebang with the exact installed path
#                    so gem, irb, erb, … all invoke the bundled interpreter.

require "pathname"

abort "Usage: #{$PROGRAM_NAME} <runtime-prefix>" if ARGV.empty?

prefix   = Pathname.new(ARGV[0]).expand_path
ruby_bin = prefix / "bin/ruby"

abort "ERROR: #{ruby_bin} not found" unless ruby_bin.exist?

# ── 1. rbconfig.rb prefix fix ─────────────────────────────────────────────────
# Runtimes built before this fix embedded wrong relative-path arithmetic.
# Replace the two-line _bin_dir + _prefix block with the correct __dir__ form.
Pathname.glob("#{prefix}/lib/ruby/*/*/rbconfig.rb").each do |path|
  src = path.read
  next unless src.include?("runtime relocation patch")

  patched = src.gsub(/( *)_bin_dir = [^\n]+\n\1_prefix\s+=\s+[^\n]+/) do
    "#{Regexp.last_match(1)}_prefix = File.expand_path(\"../../../..\", __dir__)"
  end
  path.write(patched) unless patched == src
end

# ── 2. Dylib load path ────────────────────────────────────────────────────────
otool_out = IO.popen(["otool", "-L", ruby_bin.to_s], err: :close, &:read)
old_dylib = otool_out.lines
                     .map { |l| l.strip.split.first }
                     .find { |p| p&.match?(/libruby\.\d+\.\d+\.dylib$/) }

if old_dylib && !old_dylib.start_with?("@")
  lib_name = File.basename(old_dylib)
  system "install_name_tool", "-change", old_dylib,
         "@loader_path/../lib/#{lib_name}", ruby_bin.to_s
end

# ── 3. Script shebangs ────────────────────────────────────────────────────────
shebang = "#!#{ruby_bin}".b
Pathname.glob("#{prefix}/bin/*").each do |f|
  next if f.symlink? || !f.file?

  raw = f.binread
  next unless raw.start_with?("#!")
  next unless raw[0, raw.index("\n") || raw.size].include?("ruby")

  new_content = shebang + raw[raw.index("\n") || raw.size..]
  next if new_content == raw

  mode = f.stat.mode & 0o7777
  File.open(f.to_s, "wb") { |io| io.write(new_content) }
  File.chmod(mode, f.to_s)
end
