require 'sinatra/base'
require 'pp'

class Layer1 < Sinatra::Base
  use Xaction::Rack, "layer1"
  helpers Xaction::SinatraHelpers

  get '/' do
    xaction_helper.logger.debug "Layer 1"
    xaction_helper.http.get("http://layer2.example.org:9393/").body
  end
end

class Layer2 < Sinatra::Base
  use Xaction::Rack, "layer2"
  helpers Xaction::SinatraHelpers

  get '/' do
    xaction_helper.logger.debug "Layer 2"
    xaction_helper.http.get("http://layer3.example.org:9393/").body
  end
end

class Layer3 < Sinatra::Base
  use Xaction::Rack, "layer3"
  helpers Xaction::SinatraHelpers

  get '/' do
    xaction_helper.logger.debug "Layer 3"
    "from layer 3"
  end
end
