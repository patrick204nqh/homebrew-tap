# frozen_string_literal: true

require "net/http"
require "uri"
require "digest"
require "tap_gen/gem_resource"

module TapGen
  # Resolves a gem name+version to a concrete RubyGems download and its
  # sha256, preferring the arm64-darwin platform build when one exists.
  module Rubygems
    DOWNLOAD = "https://rubygems.org/downloads"
    PLATFORM = "arm64-darwin"

    module_function

    # `fetcher` is injectable so the selection logic can be unit-tested
    # without network; production callers use the default (real HTTP fetch).
    def resolve(name, version, fetcher: method(:fetch))
      platform_url = "#{DOWNLOAD}/#{name}-#{version}-#{PLATFORM}.gem"
      body = fetcher.call(platform_url)
      if body
        return GemResource.new(name: name, version: version, platform: PLATFORM,
                               sha256: Digest::SHA256.hexdigest(body))
      end

      pure_url = "#{DOWNLOAD}/#{name}-#{version}.gem"
      body = fetcher.call(pure_url)
      raise "could not download #{name} #{version} (tried platform + pure)" unless body

      GemResource.new(name: name, version: version,
                      sha256: Digest::SHA256.hexdigest(body))
    end

    # Returns the response body for a 200, or nil when the gem is absent.
    # RubyGems' object store answers a missing download with 403 (S3-style),
    # not 404, so both are treated as "absent". Redirects are followed. Any
    # other status (e.g. 5xx) raises rather than returning nil — a transient
    # server error must not be misread as "gem does not exist", which would
    # silently pick the wrong download/sha256.
    def fetch(url, redirects: 5)
      uri = URI(url)
      (redirects + 1).times do
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                                  open_timeout: 10, read_timeout: 30) do |http|
          http.get(uri.request_uri, "User-Agent" => "tap-gen/1.0")
        end
        case res
        when Net::HTTPSuccess                       then return res.body
        when Net::HTTPNotFound, Net::HTTPForbidden  then return nil
        when Net::HTTPRedirection                   then uri = URI.join(uri.to_s, res["location"])
        else raise "unexpected HTTP #{res.code} fetching #{uri}"
        end
      end
      raise "too many redirects fetching #{url}"
    end
  end
end
