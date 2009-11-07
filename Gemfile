source "http://gemcutter.org"

gem "halorgium-activesupport",  '=3.0.pre', :require_as => nil
gem "rack-client",              '~>0.2.1',  :require_as => nil

only :test do
  gem "mongrel"
  gem "sinatra",  :require_as => 'sinatra/base'
  gem "rake"
  gem "rspec",    :require_as => "spec"
  gem "bundler"
end

disable_system_gems
