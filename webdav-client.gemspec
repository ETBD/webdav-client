# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/webdav/version'

Gem::Specification.new do |gem|
  gem.name          = "webdav-client"
  gem.version       = Net::Webdav::VERSION
  gem.authors       = ["Tom Canham"]
  gem.email         = ["alphasimian@gmail.com"]
  gem.description   = %q{Webdav client}
  gem.summary       = %q{Webdav client}
  gem.homepage      = "https://github.com/ETBD/webdav-client"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency "curb"
  
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "rake"
end
