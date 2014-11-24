require 'operation'
require 'httparty'
require 'active_support/concern'
require 'active_support/core_ext/string'

module Remotr
  module Respondable
    extend ActiveSupport::Concern

    module ClassMethods
      def config
        self.name.deconstantize.constantize.config
      end

      def namespace
        self.name.demodulize.pluralize.underscore
      end

      def application
        self.name.deconstantize.underscore
      end

      def get(path = {}, params = {})
        request :get, path, params
      end

      def post(path = {}, params = {}, body = nil)
        request :post, path, params
      end

      def delete(path = {}, params = {})
        request :delete, path, params
      end

      def put(path = {}, params = {}, body = nil)
        request :put, path, params
      end

      def request(method, path, params, body = nil)
        url = URI.join(config.base_uri, "#{config.base_path}#{path}").to_s
        fail ArgumentError unless %w( get post delete put update ).include? method.to_s

        HTTParty.send method, url,
                      query: params,
                      headers: { 'Accept' => 'application/json' },
                      basic_auth: { username: 'api', password: config.api_key }
      end

      def respond_with(httparty_response, custom_namespace = nil)
        use_namespace = custom_namespace || namespace
        object = httparty_response.parsed_response ? httparty_response.parsed_response[use_namespace.to_s] : nil

        if httparty_response.code.to_i.between? 200, 299
          Operations.success :remote_request_succeeded, object: object, code: httparty_response.code, body: httparty_response.body
        else
          Operations.failure :remote_request_failed, object: httparty_response, code: httparty_response.code
        end

      rescue JSON::ParserError
        Operations.failure :remote_request_parsing_failed, object: httparty_response
      end

    end

  end
end
