require 'rack/client'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/notifications'
require 'active_support/buffered_logger'

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
      ActiveSupport::Notifications.instrument(:sleuth, payload) do
        yield
      end
    end

    def transaction(current_name, parent = nil)
      ActiveSupport::Notifications.transaction do
        Transaction.create(current_name, current_id, parent)

        yield
      end
    end

    def current_id
      ActiveSupport::Notifications.transaction_id
    end

    def current_transaction
      Transaction.running[current_id]
    end

    def watch(log_path)
      logger = ActiveSupport::BufferedLogger.new(log_path)
      ActiveSupport::Notifications.subscribe('sleuth') do |*args|
        logger.debug(Transaction.message_for(*args))
      end
    end
  end
end

current_dir = File.expand_path(File.dirname(__FILE__) + '/sleuth')
require current_dir + '/middleware'
require current_dir + '/outbound_handler'
require current_dir + '/transaction'
