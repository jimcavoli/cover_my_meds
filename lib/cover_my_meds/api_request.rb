require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'json'
require 'hashie'
require 'active_support/core_ext/object/to_param'
require 'active_support/core_ext/object/to_query'
require 'cover_my_meds/error'


module CoverMyMeds
  module ApiRequest
    DEFAULT_TIMEOUT = 60 #seconds, matches Net::Http's default which rest-client used

    def request(http_method, host, path, params={}, auth_type = :basic, &block)
      params  = params.symbolize_keys
      headers = params.delete(:headers) || {}

      conn = Faraday.new host do |faraday|
        faraday.adapter :typhoeus
      end
      case auth_type
      when :basic
        conn.basic_auth @username, @password
      when :bearer
        conn.authorization :Bearer, "#{@username}+#{params.delete(:token_id)}"
      end

      response = conn.send http_method do |request|
        request.url path
        request.options.timeout = DEFAULT_TIMEOUT
        request.params = params
        request.headers.merge! headers
        request.body = yield if block_given?
      end
      raise Error::HTTPError.new(response.status, response.body, http_method, conn) unless response.success?

      parse_response response
    end

    def parse_response response
      return nil if response.body.empty?
      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end
  end
end
