require 'rack/client'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/notifications'
require 'active_support/buffered_logger'

module Xaction
  TRANSACTION_HEADER = "X_TRANSACTION"

  mattr_reader :transactions
  @@transactions = {}

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
end

current_dir = File.expand_path(File.dirname(__FILE__) + '/xaction')
require current_dir + '/middleware'
require current_dir + '/outbound_handler'
require current_dir + '/transaction'
