require "net/http"
require "net/http/post/multipart"
require "json"

module Appcanary
  require 'securerandom'

  class ServiceError < RuntimeError
  end

  # In this module, `config` should always be a hash, or an object that responds
  # to `[](k)`, typically obtained by calling `Appcanary::Configuration#resolve!`.
  module HTTP
    def ship_gemfile(endpoint, config, &block)
      payload = {
        file: config[:gemfile_lock_path],
        platform: "ruby"
      }

      parsed_response = ship_file(endpoint, payload, config)

      if block
        block.call(parsed_response)
      else
        parsed_response
      end
    end

    def ship_file(endpoint, payload, config)
      resp = try_request_with(:put, endpoint, payload, config)

      unless resp.code.to_s == "200"
        resp = try_request_with(:post, endpoint, payload, config)
      end

      unless %w[200 201].include? resp.code.to_s
        raise ServiceError.new("Failed to ship file to Appcanary: #{resp.message}")
      end

      JSON.parse(resp.body)
    end

    private
    def url_for(endpoint, config)
      case endpoint
      when :monitors
        monitor = "#{config[:monitor_name]}"

        if ENV["CIRCLECI"] && ENV["CIRCLECI"] == "true"
          monitor = "#{monitor}_#{ENV['CIRCLE_BRANCH']}"
        end

        # these are rails routing delimiters
        monitor.gsub!("/", "_")
        monitor.gsub!(".", "_")

        URI.parse("#{config[:base_uri]}/monitors/#{monitor}")
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

        headers = {"Authorization" => "Token #{config[:api_key]}"}
        req = request_type.new(url.path, params, headers, SecureRandom.base64)
        options = { use_ssl: url.scheme == "https" }

        Net::HTTP.start(url.host, url.port, options) do |http|
          http.request(req)
        end
      end
    end
  end
end
