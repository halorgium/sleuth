require 'rack/client'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/notifications'
require 'active_support/buffered_logger'

module Xaction
  TRANSACTION_HEADER = "X_TRANSACTION"

  mattr_reader :transactions
  @@transactions = {}

  class Transaction < Struct.new(:name, :id, :log_path, :parent)
    def log(event)
      parts = [format_time(event.time), format_time(event.end), event.duration,
               full_name, parent, event.payload.inspect]
      message = "%s %s %0.4f %s %s -- %s" % parts

      logger.debug(message)
    end

    def format_time(time)
      "%s%06d" % [time.utc.iso8601, time.usec]
    end

    def logger
      @logger ||= ActiveSupport::BufferedLogger.new(log_path)
    end

    def full_name
      "#{name}-#{id}"
    end
  end

  class << self
    delegate :head, :get, :post, :put, :delete, :to => :http

    def http
      @http ||= Rack::Client.new {
        use OutboundHeader
      }
    end

    def instrument(payload)
      ActiveSupport::Notifications.instrument(:xaction, payload) do
        yield
      end
    end

    def transaction(current_name, log_path, parent = nil)
      ActiveSupport::Notifications.transaction do
        transactions[current_id] = Transaction.new(current_name, current_id, log_path, parent)

        yield
      end
    end

    def current_id
      ActiveSupport::Notifications.transaction_id
    end

    def current_transaction
      transactions[current_id]
    end

    def watch
      ActiveSupport::Notifications.subscribe('xaction') do |*args|
        event        = ActiveSupport::Notifications::Event.new(*args)
        transaction  = transactions[event.transaction_id]
        transaction.log(event)
      end
    end
  end

  class Middleware
    def initialize(app, name, log_path)
      @app, @name, @log_path = app, name, log_path
    end

    def call(env)
      parent = env["HTTP_#{TRANSACTION_HEADER}"]

      Xaction.transaction(@name, @log_path, parent) do
        request = Rack::Request.new(env)
        code, headers, body = Xaction.instrument("Received #{request.request_method} #{request.url}") do
          @app.call(env)
        end
        headers[TRANSACTION_HEADER] = Xaction.current_transaction.full_name
        [code, headers, body]
      end
    end
  end

  class OutboundHeader
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      Xaction.instrument("Sending #{request.request_method} #{request.url}") do
        env["HTTP_#{TRANSACTION_HEADER}"] = Xaction.current_transaction.full_name
        @app.call(env)
      end
    end
  end
end
