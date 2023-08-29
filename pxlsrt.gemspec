# frozen_string_literal: true

require './lib/pxlsrt/version'

Gem::Specification.new do |spec|
  spec.name          = 'pxlsrt'
  spec.version       = Pxlsrt::VERSION
  spec.authors       = ['EVA-01']
  spec.email         = ['j.bruno.che@gmail.com']
  spec.summary       = 'Pixel sort PNG files.'
  spec.description   = 'Pixel sort PNG files with ease!'
  spec.homepage      = 'https://github.com/czycha/pxlsrt'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = ['pxlsrt']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.2'
  spec.add_dependency 'oily_png', '~> 1.2.1'
  spec.add_dependency 'thor', '~> 0.18'
end
