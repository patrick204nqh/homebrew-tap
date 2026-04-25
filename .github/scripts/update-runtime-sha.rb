#!/usr/bin/env ruby
# frozen_string_literal: true

# Updates the ruby-runtime resource sha256 in all formulas.
# Usage: update-runtime-sha.rb <new_sha256> [formula_files...]

abort "Usage: #{$PROGRAM_NAME} <sha256> [formula...]" if ARGV.empty?

new_sha = ARGV.shift
formulas = ARGV.empty? ? Dir["Formula/*.rb"] : ARGV

formulas.each do |path|
  src = File.read(path)
  next unless src.include?('resource "ruby-runtime"')

  patched = src.sub(
    /(resource\s+"ruby-runtime"\s+do\b.*?^\s+sha256\s+)"[a-f0-9]{64}"/m,
    "\\1\"#{new_sha}\""
  )

  if patched == src
    warn "WARNING: no sha256 updated in #{path}"
    next
  end

  File.write(path, patched)
  puts "Updated #{path}"
end
