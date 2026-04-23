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

  in_resource = false
  patched = src.each_line.map do |line|
    in_resource = true if line.include?('resource "ruby-runtime"')
    if in_resource && line.match?(/^\s+sha256 "[a-f0-9]{64}"/)
      in_resource = false
      line.sub(/"[a-f0-9]{64}"/, "\"#{new_sha}\"")
    else
      line
    end
  end.join

  if patched == src
    warn "WARNING: no sha256 updated in #{path}"
    next
  end

  File.write(path, patched)
  puts "Updated #{path}"
end
