require 'rack/client'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/notifications'
require 'active_support/buffered_logger'

require 'time'

module Sleuth
  TRANSACTION_HEADER = "X_SLEUTH_TRANSACTION"

  class << self
    delegate :head, :get, :post, :put, :delete, :to => :http

    def http
      @http ||= Rack::Client.new {
        use OutboundHeader
      }
    end

    def instrument(payload)
      if inside_transaction?
        ActiveSupport::Notifications.instrument(:sleuth, payload) do
          yield
        end
      else
        yield
      end
    end

    def transaction(current_name, parent = nil)
      ActiveSupport::Notifications.transaction do
        Transaction.create(current_name, parent)

        yield
      end
    end

    def current_id
      ActiveSupport::Notifications.transaction_id
    end

    def current_transaction
      Transaction.running[current_id]
    end

    def inside_transaction?
      current_transaction
    end

    def thread(name)
      parent = current_transaction && current_transaction.full_name
      Thread.new {
        transaction(name, parent) do
          yield
        end
      }
    end

    def watch(log_path)
      logger = ActiveSupport::BufferedLogger.new(log_path)
      subscribe do |event|
        logger.debug(event.message)
      end
    end

    def subscribe
      ActiveSupport::Notifications.subscribe('sleuth') do |*args|
        yield Event.new(*args)
      end
    end
  end
end

current_dir = File.expand_path(File.dirname(__FILE__) + '/sleuth')
require current_dir + '/middleware'
require current_dir + '/outbound_handler'
require current_dir + '/event'
require current_dir + '/transaction'
