module Sleuth
  class Event < ActiveSupport::Notifications::Event
    def formatted_time
      "%s%06d" % [time.utc.iso8601, time.usec]
    end

    def formatted_end
      "%s%06d" % [@end.utc.iso8601, @end.usec]
    end

    def transaction
      Transaction.running[transaction_id]
    end

    def message
      parts = [formatted_time, formatted_end, transaction.full_name,
               transaction.parent || '-', duration, payload.inspect]
      "%s %s %s %s %0.4f -- %s" % parts
    end
  end
end
