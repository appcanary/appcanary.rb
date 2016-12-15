require "net/http"
require "net/http/post/multipart"
require "json"

module Appcanary
  class ServiceError < RuntimeError
  end

  class << self
    def try_request_with(request_type, endpoint)
      url = URI.parse("#{config[:base_uri]}/#{endpoint.to_s}/#{config[:name]}")
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
          http.request(req)
        end
      end
    end

    def ship_gemfile(endpoint = :monitors, &block)
      resp = try_request_with Net::HTTP::Put::Multipart, endpoint

      unless resp.code.to_s == "200"
        resp = try_request_with Net::HTTP::Post::Multipart, endpoint
      end

      unless ["200", "201"].include? resp.code.to_s
        raise ServiceError.new("Could not connect to Appcanary: #{resp}")
      end

      parsed_response = JSON.parse(resp.body)

      if block
        block.call(parsed_response)
      else
        parsed_response
      end
    end
  end
end
