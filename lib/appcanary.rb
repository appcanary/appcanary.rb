require "appcanary/version"
require "net/http"
require "net/http/post/multipart"
require "yaml"
require "json"

module Appcanary
  APPCANARY_BASE_URI = "https://appcanary.com/api/v3/monitors"

  def config
    {}.tap do |m|
      if defined?(Rails)
        m[:token] = Rails.configuration.appcanary.api_token
        m[:name] = Rails.configuration.appcanary.monitor_name
        m[:base_uri] = Rails.configuration.appcanary.base_uri
      else
        begin
          yaml_config = YAML.load_file("#{Bundler.root}/appcanary.yml")
          m[:token] = yaml_config["api_token"]
          m[:name] = yaml_config["monitor_name"]
          m[:base_uri] = yaml_config["base_uri"]
        rescue => e
          puts "Error: #{e}"
        end
      end
      m[:base_uri] ||= APPCANARY_BASE_URI
    end
  end

  def try_request_with(request_type)
    url = URI.parse("#{config[:base_uri]}/#{config[:name]}")
    filename = File.basename(Bundler.default_lockfile)
    url.query = URI.encode_www_form("platform" => "ruby")
    File.open(Bundler.default_lockfile) do |lockfile|
      params = {
        "file" => UploadIO.new(lockfile, "text/plain", filename),
        "platform" => "ruby"
      }
      headers = {
        "Authorization" => "Token #{config[:token]}"
      }
      Net::HTTP.start(url.host, url.port) do |http|
        req = request_type.new(url.path, params, headers, SecureRandom.base64)
        http.request(req).tap { |resp| puts "Got response: #{resp}" }
      end
    end
  end

  def ship_gemfile
    resp = try_request_with Net::HTTP::Put::Multipart
    unless resp.code.to_s == "200"
      resp = try_request_with Net::HTTP::Post::Multipart
    end
    resp
  end
end
