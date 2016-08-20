$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "contract/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "contract"
  s.version     = Contract::VERSION
  s.authors     = "Noven Effendi"
  s.email       = "noveneffendi@gmail.com"
  s.homepage    = "www.spidersmartsystem.com"
  s.summary     = "Sales quotation module and Sales invoice module"
  s.description = "Engine for add Sales Quotation module."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.12"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "pg"
  s.add_development_dependency "will_paginate"
end
