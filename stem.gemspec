$spec = Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'sprout'
  s.version = '0.2.1'
  s.date = '2011-03-24'

  s.description = "Elegant, interactive EC2 Management"
  s.summary     = "An Ec2 management system designed to help you quickly define a new instance, create N clones of said instance and start/stop them"

  s.authors = ["Kevin Poorman"]
  s.email = ["kpoorman@bandwidth.com"]

  # = MANIFEST =
  s.files = %w[LICENSE README.md] + Dir["lib/**/*.rb"]

  s.executables = ["sprout"]

  # = MANIFEST =
  s.add_dependency 'swirl',    '~> 1.7.5'
  s.add_dependency 'thor',     '~> 0.14.6'
  s.add_dependency 'terminal-table', '~> 1.4.2'
  s.add_dependency 'awesome_print', '~> 0.3.2'
  s.add_dependency 'json'
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.add_development_dependency 'rspec-core', '~> 2.5.0'
  s.add_development_dependency 'rspec-expectations', '~> 2.5.0'
  s.add_development_dependency 'rspec-mocks', '~> 2.5.0'
  s.add_development_dependency 'vcr', '~> 1.6.0'
  s.add_development_dependency 'webmock', '~> 1.6.2'
  s.homepage = "https://github.com/noeticpenguin/Sprout"
  s.require_paths = %w[lib]
end
