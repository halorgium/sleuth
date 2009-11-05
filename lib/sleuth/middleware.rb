module Sleuth
  class Middleware
    def initialize(app, name)
      @app, @name = app, name
    end

    def call(env)
      parent = env["HTTP_#{TRANSACTION_HEADER}"]

      Sleuth.transaction(@name, parent) do
        request = Rack::Request.new(env)
        code, headers, body = Sleuth.instrument("Received #{request.request_method} #{request.url}") do
          @app.call(env)
        end
        headers[TRANSACTION_HEADER] = Sleuth.current_transaction.full_name
        [code, headers, body]
      end
    end
  end
end
