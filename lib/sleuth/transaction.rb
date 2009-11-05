module Sleuth
  class Event < ActiveSupport::Notifications::Event
    def formatted_time
      "%s%06d" % [time.utc.iso8601, time.usec]
    end

    def formatted_end
      "%s%06d" % [@end.utc.iso8601, @end.usec]
    end
  end

  class Transaction < Struct.new(:name, :id, :stamp, :pid, :log_path, :parent)
    def self.create(name, id, log_path, parent)
      Sleuth.transactions[id] = new(name, id, Time.now.to_i, Process.pid, log_path, parent)
    end

    def log(event)
      parts = [event.formatted_time, event.formatted_end,
               full_name, parent || '-', event.duration, event.payload.inspect]
      message = "%s %s %s %s %0.4f -- %s" % parts

      logger.debug(message)
    end

    def logger
      @logger ||= ActiveSupport::BufferedLogger.new(log_path)
    end

    def full_name
      "#{name}-#{id}-#{stamp}-#{pid}"
    end
  end
end
