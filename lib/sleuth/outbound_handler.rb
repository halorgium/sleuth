module Sleuth
  class OutboundHeader
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      Sleuth.instrument("Sending #{request.request_method} #{request.url}") do
        if Sleuth.inside_transaction?
          env["HTTP_#{TRANSACTION_HEADER}"] = Sleuth.current_transaction.full_name
        end
        @app.call(env)
      end
    end
  end
end
