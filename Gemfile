source "http://spork.in/xaction.gem/"

gem "activesupport",  '=3.0.pre.xaction.0'
gem "rack-client",    '=0.2.0.pre',         :require_as => 'rack/client'

only :test do
  gem "mongrel"
  gem "sinatra",  :require_as => 'sinatra/base'
  gem "rspec",    :require_as => "spec"
end

disable_system_gems