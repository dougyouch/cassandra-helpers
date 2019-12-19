# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'cassandra-helpers'
  s.version     = '0.1.1'
  s.licenses    = ['MIT']
  s.summary     = 'Cassandra Helper Methods'
  s.description = 'Utility methods for working with Cassandra'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/cassandra-helpers'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  s.add_runtime_dependency 'cassandra-driver'
end
