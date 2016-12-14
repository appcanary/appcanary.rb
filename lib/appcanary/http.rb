require "net/http"
require "net/http/post/multipart"

module Appcanary
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
