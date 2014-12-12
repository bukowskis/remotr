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
        request :post, path, params, body
      end

      def delete(path = {}, params = {})
        request :delete, path, params
      end

      def put(path = {}, params = {}, body = nil)
        request :put, path, params, body
      end

      def request(method, path, params = {}, body = nil)
        path         = "#{config.base_path}#{path}"
        token        = Signature::Token.new application, config.api_key
        request      = Signature::Request.new method.to_s.upcase, path, params
        auth_hash    = request.sign token
        query_params = params.merge auth_hash
        url          = URI.join(config.base_uri, path).to_s

        fail ArgumentError unless %w( get post delete put update ).include? method.to_s
        httparty_response = HTTParty.send method, url, timeout: timeout_in_seconds, query: query_params, body: body, headers: { 'Accept' => 'application/json' }

        if httparty_response.code.to_i.between? 200, 299
          Operations.success :request_succeeded, object: httparty_response
        else
          Operations.failure :request_failed, object: httparty_response
        end

      rescue => exception
        Operations.failure :connection_failed, object: exception
      end

      def respond_with(request_operation, namespace_to_use = namespace)
        return request_operation if request_operation.failure?
        httparty_response = request_operation.object
        parsed_response = httparty_response.parsed_response

        return Operations.failure(:response_is_not_parseable, object: httparty_response) unless parsed_response
        return Operations.failure(:response_missing_success_flag, object: httparty_response) unless parsed_response && parsed_response.respond_to?(:key?) && parsed_response.key?('success')

        code    = parsed_response['code'].to_s != '' ? parsed_response['code'].to_sym : :response_unsuccessful
        message = parsed_response['message'].to_s != '' ? parsed_response['message'] : code.to_s
        return Operations.failure(code, object: httparty_response, message: message) if parsed_response['success'].to_s != 'true'

        code   = parsed_response['code'].to_s != '' ? parsed_response['code'].to_sym : :request_succeeded
        object = parsed_response[namespace_to_use.to_s]
        Operations.success code, object: object

      rescue JSON::ParserError
        Operations.failure :json_parsing_failed, object: httparty_response
      end

      def timeout_in_seconds
        config.default_timeout
      end
    end

  end
end
