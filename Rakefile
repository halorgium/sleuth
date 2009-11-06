require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "sleuth"
  s.version = "0.2.1.pre"
  s.summary = "Transaction logging middleware"
  s.author = "Tim Carey-Smith"
  s.email = "dev@spork.in"
  s.files = FileList["lib/**/*.rb"]

  require 'bundler'
  manifest = Bundler::Environment.load(File.dirname(__FILE__) + '/Gemfile')
  manifest.dependencies.each do |d|
    next if d.only && d.only.include?('test')
    s.add_dependency(d.name, d.version)
  end
end

Rake::GemPackageTask.new(spec) do |t|
  t.gem_spec = spec
end
