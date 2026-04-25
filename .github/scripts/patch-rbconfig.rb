#!/usr/bin/env ruby
# frozen_string_literal: true

# Patches rbconfig.rb so that CONFIG prefix values are corrected at runtime
# relative to the actual installed location instead of the build-time prefix.
#
# Usage: patch-rbconfig.rb <rbconfig_path> <build_prefix>
#
# The patch is appended at the top level AFTER the module definition so that
# RbConfig::CONFIG and RbConfig::MAKEFILE_CONFIG are already fully initialised
# when the gsub! runs.  Injecting inside the module body caused NameError
# because CONFIG is referenced before it is defined.

abort "Usage: #{$PROGRAM_NAME} <rbconfig_path> <build_prefix>" unless ARGV.length == 2

rbconfig_path, build_prefix = ARGV
abort "ERROR: #{rbconfig_path} not found" unless File.exist?(rbconfig_path)

src = File.read(rbconfig_path)
abort "ERROR: could not find 'module RbConfig' in #{rbconfig_path}" unless src.include?("module RbConfig")

if src.include?("runtime relocation patch")
  puts "Already patched: #{rbconfig_path}"
  exit 0
end

patch = <<~RUBY

  # --- runtime relocation patch (added by patch-rbconfig.rb) ---
  _reloc_prefix = File.expand_path("../../../..", __dir__)
  RbConfig::CONFIG.each_value          { |v| v.gsub!(#{build_prefix.inspect}, _reloc_prefix) rescue FrozenError }
  RbConfig::MAKEFILE_CONFIG.each_value { |v| v.gsub!(#{build_prefix.inspect}, _reloc_prefix) rescue FrozenError }
  # --- end patch ---
RUBY

File.write(rbconfig_path, src + patch)
puts "Patched #{rbconfig_path}"
