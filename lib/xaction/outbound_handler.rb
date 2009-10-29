module Xaction
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
