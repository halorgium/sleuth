require 'sinatra/base'
require 'pp'

LOG_PATH = File.dirname(__FILE__) + '/logs'

class Layer1 < Sinatra::Base
  use Sleuth::Middleware, "layer1", LOG_PATH + '/1.log'

  get '/' do
    Sleuth.instrument(:server => :layer_1) do
      Sleuth.get("http://layer2.example.org:9393/").body
    end
  end
end

class Layer2 < Sinatra::Base
  use Sleuth::Middleware, "layer2", LOG_PATH + '/2.log'

  get '/' do
    Sleuth.instrument(:api => 1) do
      sleep 0.1
      Sleuth.instrument(:api => 2) do
        sleep 0.2
      end
    end
    body = Sleuth.instrument(:server => :layer_2) do
      Sleuth.get("http://layer3.example.org:9393/").body
    end
    Sleuth.instrument(:api => 3) do
      sleep 0.3
      Sleuth.instrument(:api => 4) do
        sleep 0.4
      end
    end
    body
  end
end

class Layer3 < Sinatra::Base
  use Sleuth::Middleware, "layer3", LOG_PATH + '/3.log'

  get '/' do
    Sleuth.instrument(:server => :layer_3) do
      sleep 1
      "from layer 3: #{ActiveSupport::SecureRandom.hex(20)}\n"
    end
  end
end
