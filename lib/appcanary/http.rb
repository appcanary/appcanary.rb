require "net/http"
require "net/http/post/multipart"
require "json"

module Appcanary
  class ServiceError < RuntimeError
  end

  module HTTP
    def ship_gemfile(endpoint, config, &block)
      payload = {
        file: Bundler.default_lockfile,
        platform: "ruby"
      }

      resp = try_request_with(:put, endpoint, payload, config)

      unless resp.code.to_s == "200"
        resp = try_request_with(:post, endpoint, payload, config)
      end

      unless %w[200 201].include? resp.code.to_s
        raise ServiceError.new("Could not connect to Appcanary: #{resp}")
      end

      parsed_response = JSON.parse(resp.body)

      if block
        block.call(parsed_response)
      else
        parsed_response
      end
    end

    private
    def url_for(endpoint, config)
      case endpoint
      when :monitors
        URI.parse("#{config[:base_uri]}/monitors/#{config[:name]}")
      when :check
        URI.parse("#{config[:base_uri]}/check")
      else
        # internal brokenness
        raise RuntimeError.new("Unknown Appcanary endpoint: #{endpoint.to_s}!")
      end
    end

    REQUEST_TYPES = {
      post: Net::HTTP::Post::Multipart,
      put: Net::HTTP::Put::Multipart
    }

    def try_request_with(method, endpoint, payload, config)
      request_type = REQUEST_TYPES[method]
      url = url_for(endpoint, config)
      filename = File.basename(payload[:file])
      url.query = URI.encode_www_form("platform" => payload[:platform])

      File.open(payload[:file]) do |file|
        params = {}.tap do |p|
          p["file"] = UploadIO.new(file, "text/plain", filename)
          p["platform"] = payload[:platform]

          if payload[:version]
            p["version"] = payload[:version]
            url.query = url.query.merge("version", payload[:version])
          end
        end

        headers = {"Authorization" => "Token #{config[:token]}"}

        Net::HTTP.start(url.host, url.port) do |http|
          req = request_type.new(url.path, params, headers, SecureRandom.base64)
          http.request(req)
        end
      end
    end
  end
end
