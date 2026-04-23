#!/usr/bin/env ruby
# frozen_string_literal: true

# Patches rbconfig.rb so that CONFIG prefix/exec_prefix values are computed at
# runtime relative to the ruby binary location instead of being hardcoded to
# the build-time prefix.
#
# Usage: patch-rbconfig.rb <rbconfig_path> <build_prefix>

abort "Usage: #{$PROGRAM_NAME} <rbconfig_path> <build_prefix>" unless ARGV.length == 2

rbconfig_path, build_prefix = ARGV
abort "ERROR: #{rbconfig_path} not found" unless File.exist?(rbconfig_path)

relocation_block = <<~RUBY

  # --- runtime relocation patch (added by patch-rbconfig.rb) ---
  _prefix = File.expand_path("../../../..", __dir__)
  CONFIG.each_value            { |v| v.gsub!(#{build_prefix.inspect}, _prefix) rescue nil }
  MAKEFILE_CONFIG.each_value   { |v| v.gsub!(#{build_prefix.inspect}, _prefix) rescue nil }
  # --- end patch ---
RUBY

src = File.read(rbconfig_path)
patched = src.sub(/^(module RbConfig\n)/, "\\1#{relocation_block}")

abort "ERROR: could not find 'module RbConfig' in #{rbconfig_path}" if patched == src

File.write(rbconfig_path, patched)
puts "Patched #{rbconfig_path}"
