Bundler.require_env

Thread.abort_on_exception = true

require File.dirname(__FILE__) + '/../lib/sleuth'

require File.dirname(__FILE__) + '/layers'

run Rack::URLMap.new("http://layer1.example.org/" => Layer1,
                     "http://layer2.example.org/" => Layer2,
                     "http://layer3.example.org/" => Layer3)

Xaction.watch
