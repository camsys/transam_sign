$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "transam_sign/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "transam_sign"
  s.version     = TransamSign::VERSION
  s.authors     = ["Julian Ray"]
  s.email       = ["jray@camsys.com"]
  s.homepage    = "http://www.camsys.com"
  s.summary     = "Traffic Sign Extensions for TransAM."
  s.description = "Traffic Sign Extensions for TransAM."
  s.license     = "MIT"

  s.metadata = { "load_order" => "2" }

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '~> 5.2'

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "codacy-coverage"
  s.add_development_dependency 'simplecov'
end
