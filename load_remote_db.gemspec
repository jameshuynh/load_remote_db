lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'load_remote_db/version'

Gem::Specification.new do |spec|
  spec.name          = 'load_remote_db'
  spec.version       = LoadRemoteDb::VERSION
  spec.authors       = ['James Huynh']
  spec.email         = ['james@rubify.com']

  spec.summary       = 'Load MySQL Remote DB for Mina/Capistrano'
  spec.description   = 'Load MySQL Remote DB for Mina/Capistrano'
  spec.homepage      = 'https://github.com/jameshuynh/load_remote_db'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
end
