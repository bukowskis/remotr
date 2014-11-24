Gem::Specification.new do |spec|
  spec.name        = 'remotr'
  spec.version     = '0.0.1'
  spec.date        = '2014-01-21'
  spec.summary     = "Wrapping HTTParty for our internal APIs"
  spec.description = "See https://github.com/bukowskis/remotr"
  spec.authors     = %w{ bukowskis }
  spec.homepage    = 'https://github.com/bukowskis/remotr'

  spec.files       = Dir['lib/**'] & `git ls-files -z`.split("\0")

  spec.add_dependency('httparty')
  spec.add_dependency('operation')
  spec.add_dependency('activesupport')

  spec.add_development_dependency('rspec')
  spec.add_development_dependency('guard-rspec')
  spec.add_development_dependency('rb-fsevent')
  spec.add_development_dependency('webmock')
end
