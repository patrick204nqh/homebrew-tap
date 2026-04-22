#!/usr/bin/env ruby
# frozen_string_literal: true

# Updates a Homebrew formula with a new version and SHA256.
# Strips the stale bottle block; preserves gem resource blocks unchanged.
#
# Usage: update-formula.rb <formula_file> <version> <sha256>

abort "Usage: #{$PROGRAM_NAME} <formula_file> <version> <sha256>" unless ARGV.length == 3

formula_file, version, sha256 = ARGV
abort "ERROR: #{formula_file} not found" unless File.exist?(formula_file)

puts "Updating #{formula_file} → v#{version}"

src = File.read(formula_file)

# Strip the stale bottle do...end block (it is always regenerated after a build).
# The bottle block has no nested do...end, so the non-greedy match is unambiguous.
src.gsub!(/^[ \t]*bottle do\b.*?^[ \t]*end[ \t]*\n/m, "")

# Protect gem resource blocks by working only on the text before the first `resource`.
# split(regex, 2) with a lookahead preserves the delimiter in the second part.
head, rest = src.split(/^(?=[ \t]*resource\b)/, 2)
rest ||= ""

# Update the source tarball URL version (handles both archive/refs/tags and releases/download patterns).
abort "ERROR: source URL was not updated in #{formula_file}" unless
  head.sub!(%r{((?:archive/refs/tags|releases/download)/v)\d+\.\d+\.\d+(\.tar\.gz)}, "\\1#{version}\\2")

# Update the top-level sha256 (the one that belongs to the source tarball).
abort "ERROR: sha256 was not updated in #{formula_file}" unless
  head.sub!(/sha256 "[^"]+"/, %(sha256 "#{sha256}"))

# Collapse consecutive blank lines left behind after the bottle block removal.
result = (head + rest).gsub(/\n{3,}/, "\n\n")

File.write(formula_file, result)
puts "Done."
