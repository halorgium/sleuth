module Xaction
  class Middleware
    def initialize(app, name, log_path)
      @app, @name, @log_path = app, name, log_path
    end

    def call(env)
      parent = env["HTTP_#{TRANSACTION_HEADER}"]

      Xaction.transaction(@name, @log_path, parent) do
        request = Rack::Request.new(env)
        code, headers, body = Xaction.instrument("Received #{request.request_method} #{request.url}") do
          @app.call(env)
        end
        headers[TRANSACTION_HEADER] = Xaction.current_transaction.full_name
        [code, headers, body]
      end
    end
  end
end
