# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name          = 'filtered_params'
  spec.version       = '0.0.1'
  spec.authors       = ['ITO Nobuaki']
  spec.email         = ['daydream.trippers@gmail.com']
  spec.description   = 'Strong parameters for everyone'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/dayflower/filtered_params'
  spec.license       = 'MIT'

  spec.files         = %w[
    Gemfile
    filtered_params.gemspec
    Rakefile
    README.md
    LICENSE.txt
    lib/filtered_params.rb
    test/test_helper.rb
    test/parameters_permit_test.rb
    test/parameters_require_test.rb
    test/parameters_taint_test.rb
    test/log_on_unpermitted_params_test.rb
    test/raise_on_unpermitted_params_test.rb
    test/multi_parameter_attributes_test.rb
  ]

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
end
