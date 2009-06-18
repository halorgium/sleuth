require 'rubygems'
require File.dirname(__FILE__) + '/lib/xaction'

use Xaction::Rack

require File.dirname(__FILE__) + '/layers'

map "http://layer1.example.org/" do
  run Layer1
end

map "http://layer2.example.org/" do
  run Layer2
end

map "http://layer3.example.org/" do
  run Layer3
end

#map "/" do
  #app = lambda {|env|
    #[404, {"Content-Type" => "text/plain", "Content-Length" => "12"}, ["Nothing here"]]
  #}
  #run app
#end
