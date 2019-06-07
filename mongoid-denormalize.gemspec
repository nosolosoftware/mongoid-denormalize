# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid-denormalize/version'

Gem::Specification.new do |spec|
  spec.name          = 'mongoid-denormalize'
  spec.version       = Mongoid::Denormalize::VERSION
  spec.authors       = ['rjurado01']
  spec.email         = ['rjurado01@gmail.com']

  spec.summary       = 'Denormalize fields from relations'
  spec.description   = 'Helper module for denormalizing relations attributes in Mongoid models'
  spec.homepage      = 'https://github.com/rjurado01/mongoid-denormalize'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'mongoid-compatibility', '~> 0.5.1'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'mongoid', ['>= 3.0', '< 7.0']
end
