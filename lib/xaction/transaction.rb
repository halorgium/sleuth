module Xaction
  class Transaction < Struct.new(:name, :id, :log_path, :parent)
    def log(event)
      parts = [format_time(event.time), format_time(event.end), event.duration,
               full_name, parent || '-', event.payload.inspect]
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
end
