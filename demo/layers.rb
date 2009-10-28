require 'sinatra/base'
require 'pp'

class Layer1 < Sinatra::Base
  use Xaction::Middleware, "layer1"

  get '/' do
    Xaction.instrument(:server => :layer_1) do
      Xaction.get("http://layer2.example.org:9393/").body
    end
  end
end

class Layer2 < Sinatra::Base
  use Xaction::Middleware, "layer2"

  get '/' do
    Xaction.instrument(:api => 1) do
      sleep 0.1
      Xaction.instrument(:api => 2) do
        sleep 0.2
      end
    end
    body = Xaction.instrument(:server => :layer_2) do
      Xaction.get("http://layer3.example.org:9393/").body
    end
    Xaction.instrument(:api => 3) do
      sleep 0.3
      Xaction.instrument(:api => 4) do
        sleep 0.4
      end
    end
    body
  end
end

class Layer3 < Sinatra::Base
  use Xaction::Middleware, "layer3"

  get '/' do
    Xaction.instrument(:server => :layer_3) do
      "from layer 3: #{ActiveSupport::SecureRandom.hex(20)}"
    end
  end
end
