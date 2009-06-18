require 'rack/client'
require 'logger'

module Xaction
  TRANSACTION_HEADER = "HTTP_X_TRANSACTION_ID".freeze
  HELPER_KEY = "xaction.helper".freeze

  class Rack
    def initialize(app, identifier)
      @app, @identifier = app, identifier
    end

    def call(env)
      helper = Helper.new(@identifier, env)
      env[HELPER_KEY] = helper
      helper.logger.debug "Started request"
      response = @app.call(env)
      helper.logger.debug "Finished request"
      response
    end
  end

  class Helper
    def initialize(identifier, env)
      @identifier, @env = identifier, env
    end

    def transaction_id
      @transaction_id ||= generate_transaction_id
    end

    def forwarded_transaction_id
      @forwarded_transaction_id ||= @env[TRANSACTION_HEADER] || "-"
    end

    def generate_transaction_id
      values = [
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x1000000),
        rand(0x1000000),
      ]
      "#{@identifier}-%04x%04x%04x%04x%04x%06x%06x" % values
    end

    def logger
      @logger ||= MyLogger.new(self)
    end

    def http
      @http ||= HTTPClient.new(self)
    end
  end

  class MyLogger
    def initialize(helper)
      @helper = helper
    end

    def debug(message)
      logger.debug("#{@helper.forwarded_transaction_id} #{message}")
    end

    def logger
      @logger ||= begin
        logger = Logger.new("/tmp/xaction.log")
        logger.progname = @helper.transaction_id
        logger.formatter = Formatter.new
        logger
      end
    end

    class Formatter < ::Logger::Formatter
      def call(severity, time, progname, msg)
        "%s %s %s\n" % [time.iso8601, progname, msg]
      end
    end
  end

  class HTTPClient
    def initialize(helper)
      @helper = helper
    end

    def get(*args)
      @helper.logger.debug "Making a GET request to #{args.inspect}"
      client.get(*args)
    end

    def client
      @client ||= begin
        client = ::Rack::Client.new
        client.use OutboundHeader, @helper.transaction_id
        client
      end
    end
  end

  class OutboundHeader
    def initialize(app, transaction_id)
      @app, @transaction_id = app, transaction_id
    end

    def call(env)
      env[TRANSACTION_HEADER] = @transaction_id
      @app.call(env)
    end
  end

  module SinatraHelpers
    def xaction_helper
      env[HELPER_KEY]
    end
  end
end
