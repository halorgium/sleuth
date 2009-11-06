module Sleuth
  class Event < ActiveSupport::Notifications::Event
    def formatted_time
      "%s%06d" % [time.utc.iso8601, time.usec]
    end

    def formatted_end
      "%s%06d" % [@end.utc.iso8601, @end.usec]
    end
  end

  class Transaction < Struct.new(:name, :id, :stamp, :pid, :parent)
    mattr_reader :running
    @@running = {}

    def self.create(name, parent)
      id = Sleuth.current_id
      running[id] = new(name, id, Time.now.to_i, Process.pid, parent)
    end

    def self.message_for(event)
      transaction = running[event.transaction_id]
      transaction.message_for(event)
    end

    def message_for(event)
      parts = [event.formatted_time, event.formatted_end,
               full_name, parent || '-', event.duration, event.payload.inspect]
      "%s %s %s %s %0.4f -- %s" % parts
    end

    def full_name
      "#{name}-#{id}-#{stamp}-#{pid}"
    end
  end
end
