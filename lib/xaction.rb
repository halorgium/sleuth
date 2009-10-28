require 'rack/client'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/notifications'
require 'active_support/buffered_logger'

module Xaction
  TRANSACTION_NAME_HEADER = "X_TRANSACTION_NAME"
  TRANSACTION_ID_HEADER   = "X_TRANSACTION_ID"

  mattr_reader :current_names, :parent_ids, :parent_names, :loggers
  @@current_names, @@parent_ids, @@parent_names, @@loggers = {}, {}, {}, {}

  class << self
    delegate :head, :get, :post, :put, :delete, :to => :http

    def http
      @http ||= Rack::Client.new {
        use OutboundHeader
      }
    end

    def instrument(data = {})
      payload = {
        :current_name => current_name,
        :parent_id => parent_id,
        :parent_name => parent_name,
        :data => data
      }
      ActiveSupport::Notifications.instrument(:xaction, payload) do
        yield
      end
    end

    def transaction(current_name, parent_name, parent_id, logger)
      ActiveSupport::Notifications.transaction do
        @@current_names[current_id] = current_name
        @@parent_names[current_id]  = parent_name
        @@parent_ids[current_id]    = parent_id
        @@loggers[current_id]       = logger

        instrument do
          yield
        end
      end
    end

    def current_id
      ActiveSupport::Notifications.transaction_id
    end

    def current_name
      current_names[current_id]
    end

    def parent_id
      parent_ids[current_id]
    end

    def parent_name
      parent_names[current_id]
    end

    def watch
      ActiveSupport::Notifications.subscribe('xaction') do |*args|
        event        = ActiveSupport::Notifications::Event.new(*args)

        timestamp = event.time.utc.iso8601
        current_id   = event.transaction_id
        current_name = event.payload[:current_name]
        parent_name  = event.payload[:parent_name]
        parent_id    = event.payload[:parent_id]
        data         = event.payload[:data]

        parts = [timestamp, event.time.usec, current_name, current_id,
                 parent_name, parent_id, event.duration, data.inspect]
        message = "%s%06d %s-%s %s-%s %0.4f -- %s" % parts

        loggers[current_id].debug(message)
      end
    end
  end

  class Middleware
    def initialize(app, name, log_path)
      @app, @name = app, name
      FileUtils.touch(log_path) unless File.exist?(log_path)
      @logger = ActiveSupport::BufferedLogger.new(log_path)
    end

    def call(env)
      parent_name = env["HTTP_#{TRANSACTION_NAME_HEADER}"]
      parent_id   = env["HTTP_#{TRANSACTION_ID_HEADER}"]

      Xaction.transaction(@name, parent_name, parent_id, @logger) do
        code, headers, body = @app.call(env)
        headers[TRANSACTION_NAME_HEADER] = Xaction.current_name
        headers[TRANSACTION_ID_HEADER]   = Xaction.current_id
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
      Xaction.instrument(:http_request => "#{request.request_method} #{request.url}") do
        env["HTTP_#{TRANSACTION_NAME_HEADER}"] = Xaction.current_name
        env["HTTP_#{TRANSACTION_ID_HEADER}"]   = Xaction.current_id
        @app.call(env)
      end
    end
  end
end
