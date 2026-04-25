#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks all rubygems.org resource blocks in Formula/*.rb for newer versions,
# updates formulas in place, and writes sync_gems_summary.md for the PR body.
#
# Usage: sync-gems.rb [formula_files...]

require "English"
require "net/http"
require "json"
require "digest"
require "uri"

RUBYGEMS_API  = "https://rubygems.org/api/v1/gems"
RUBYGEMS_DOWN = "https://rubygems.org/downloads"

# Matches single-line rubygems.org resource blocks (excludes ruby-runtime,
# whose URL spans multiple lines with \ continuation).
RESOURCE_RE = %r{^([ \t]*)resource "([^"]+)" do\n[ \t]*url "(https://rubygems\.org/downloads/([^"]+)\.gem)"\n[ \t]*sha256 "([a-f0-9]{64})"\n[ \t]*end[ \t]*\n?}

def http_get(url, max_redirects: 5)
  uri = URI(url)
  (max_redirects + 1).times do
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == "https",
                    read_timeout: 30, open_timeout: 10) do |http|
      res = http.get(uri.path + (uri.query ? "?#{uri.query}" : ""),
                     "User-Agent" => "homebrew-tap-sync/1.0")
      case res.code
      when "200" then return res
      when "301", "302", "303", "307", "308"
        loc = res["location"]
        uri = URI(loc.start_with?("http") ? loc : "#{uri.scheme}://#{uri.host}#{loc}")
      else # rubocop:disable Lint/DuplicateBranch
        return res
      end
    end
  end
  nil
rescue StandardError => e
  warn "  HTTP error #{url}: #{e.message}"
  nil
end

def latest_gem_version(gem_name, cache:)
  return cache[gem_name] if cache.key?(gem_name)

  sleep 0.15 # courteous to RubyGems.org rate limits
  res = http_get("#{RUBYGEMS_API}/#{gem_name}.json")
  cache[gem_name] = res&.code == "200" ? JSON.parse(res.body)["version"] : nil
rescue JSON::ParserError
  cache[gem_name] = nil
end

def sha256_for_url(url, cache:)
  return cache[url] if cache.key?(url)

  res = http_get(url)
  cache[url] = res&.code == "200" ? Digest::SHA256.hexdigest(res.body) : nil
end

def parse_version_platform(stem, gem_name)
  suffix = stem.sub(/\A#{Regexp.escape(gem_name)}-/, "")
  # Version is leading digits/dots; platform (if any) begins with a letter.
  m = suffix.match(/\A([\d.]+?)(?:-([a-zA-Z][^.]*))\z/) ||
      suffix.match(/\A([\d.]+)\z/)
  m ? [m[1], m[2]] : [suffix, nil]
end

def process_formula(path, version_cache:, sha_cache:)
  content = File.read(path)
  updates = []

  new_content = content.gsub(RESOURCE_RE) do |match|
    indent   = $LAST_MATCH_INFO[1]
    gem_name = $LAST_MATCH_INFO[2]
    stem     = $LAST_MATCH_INFO[4]
    inner    = "#{indent}  "

    old_version, platform = parse_version_platform(stem, gem_name)

    latest = latest_gem_version(gem_name, cache: version_cache)
    if latest.nil?
      warn "  #{gem_name}: API fetch failed, skipping"
      next match
    end

    next match if latest == old_version

    filename = "#{[gem_name, latest, platform].compact.join("-")}.gem"
    new_url  = "#{RUBYGEMS_DOWN}/#{filename}"
    new_sha  = sha256_for_url(new_url, cache: sha_cache)

    if new_sha.nil?
      warn "  #{gem_name}: #{latest} not downloadable#{" (#{platform})" if platform}, skipping"
      next match
    end

    updates << { gem: gem_name, from: old_version, to: latest }
    "#{indent}resource \"#{gem_name}\" do\n#{inner}url \"#{new_url}\"\n#{inner}sha256 \"#{new_sha}\"\n#{indent}end\n"
  end

  File.write(path, new_content) if new_content != content
  updates
end

formulas = ARGV.empty? ? Dir["Formula/*.rb"] : ARGV
all_updates = {}
version_cache = {}
sha_cache = {}

formulas.each do |path|
  name = File.basename(path, ".rb")
  puts "Checking #{name}..."
  updates = process_formula(path, version_cache: version_cache, sha_cache: sha_cache)
  all_updates[name] = updates unless updates.empty?
  puts updates.empty? ? "  up to date" : "  #{updates.size} update(s)"
end

summary_lines = all_updates.map do |formula, updates|
  "- `#{formula}`: #{updates.map { |u| "#{u[:gem]} #{u[:from]} → #{u[:to]}" }.join(", ")}"
end

body = if summary_lines.empty?
         "All gems up to date.\n"
       else
         "Automated weekly gem version sync.\n\n" \
           "## Updates\n\n" \
           "#{summary_lines.join("\n")}\n\n" \
           "CI will build and verify bottles before this PR can be merged.\n"
       end

File.write("sync_gems_summary.md", body)
puts summary_lines.empty? ? "\nAll gems up to date." : "\n#{summary_lines.join("\n")}"
