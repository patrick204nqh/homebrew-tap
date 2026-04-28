#!/usr/bin/env ruby
# frozen_string_literal: true

# Updates the ruby-runtime resource sha256 and RUBY_RUNTIME_VERSION in all formulas.
# Usage: update-runtime-sha.rb <new_sha256> <new_version> [formula_files...]

abort "Usage: #{$PROGRAM_NAME} <sha256> <version> [formula...]" if ARGV.length < 2

new_sha     = ARGV.shift
new_version = ARGV.shift
formulas    = ARGV.empty? ? Dir["Formula/*.rb"] : ARGV

formulas.each do |path|
  src = File.read(path)
  next unless src.include?('resource "ruby-runtime"')

  patched = src
    .sub(/RUBY_RUNTIME_VERSION\s*=\s*"[^"]+"/, "RUBY_RUNTIME_VERSION = \"#{new_version}\"")
    .sub(
      /(resource\s+"ruby-runtime"\s+do\b.*?^\s+sha256\s+)"[a-f0-9]{64}"/m,
      "\\1\"#{new_sha}\""
    )

  if patched == src
    warn "WARNING: nothing updated in #{path}"
    next
  end

  File.write(path, patched)
  puts "Updated #{path}"
end
