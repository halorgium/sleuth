module Sleuth
  class Transaction < Struct.new(:name, :id, :stamp, :pid, :parent)
    mattr_reader :running
    @@running = {}

    def self.create(name, parent)
      id = Sleuth.current_id
      running[id] = new(name, id, Time.now.to_i, Process.pid, parent)
    end

    def full_name
      "#{name}-#{id}-#{stamp}-#{pid}"
    end
  end
end
