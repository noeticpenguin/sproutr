#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'json'

class FetchCookbook
  COOKBOOK_BASE_URL = "http://cookbooks.opscode.com/api/v1/cookbooks"
  COOKBOOK_BASE_DIR = "/var/chef/cookbooks"

  def self.resolve_url(url)
    found = false
    until found
      host, port = url.host, url.port if url.host && url.port
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
      res.header['location'] ? url = URI.parse(res.header['location']) :
          found = true
    end
    res
  end

  def self.find_download_url(cookbook)
    url = URI.parse("#{COOKBOOK_BASE_URL}/#{cookbook}/")
    api_data = JSON::parse resolve_url(url).body
    version_url = api_data["latest_version"].gsub("opscode_community_http", "community.opscode.com")
    cookbook_data = JSON::parse resolve_url(URI.parse("#{version_url}/")).body
    return cookbook_data["file"]
  end

  def self.download_and_unzip(cookbook)
    system "mkdir -p #{COOKBOOK_BASE_DIR}"
    system "wget -O #{COOKBOOK_BASE_DIR}/#{cookbook}.tgz #{find_download_url(cookbook)}"
    system "tar zxvf #{COOKBOOK_BASE_DIR}/#{cookbook}.tgz -C #{COOKBOOK_BASE_DIR}"
  end

end

ARGV.each do |cookbook|
  FetchCookbook.download_and_unzip(cookbook)
end