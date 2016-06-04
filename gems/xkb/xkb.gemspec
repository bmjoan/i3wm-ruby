# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xkb/version'

Gem::Specification.new do |spec|
  spec.name          = "xkb"
  spec.version       = Xkb::VERSION
  spec.authors       = ["Joan Blackmoore"]
  spec.email         = ["blackmoore.joan@gmail.com"]
  spec.extensions    = ["ext/xkb/extconf.rb"]
  spec.summary       = %q{XKB interface for Ruby}
  spec.description   = %q{C++ Ruby extension allows you to query and set XKB group/layout state from Ruby}
  spec.homepage      = "http://members.dslextreme.com/users/jbromley/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
end
