Gem::Specification.new do |spec|
  spec.name        = 'copy_db_from_prod'
  spec.version     = '0.0.0'
  spec.date        = '2016-08-15'
  spec.summary     = "Hola!"
  spec.description = "A simple hello world gem"
  spec.authors     = ["vgulaev"]
  spec.email       = 'vgulaev@yandex.ru'
  spec.files       = ["lib/copy_db_from_prod.rb"]
  spec.executables = ["copy_db_from_prod"]
  spec.homepage    = 'http://rubygems.org/gems/copy_db_from_prod'
  spec.license     = 'MIT'

  spec.add_runtime_dependency('net-ssh')
end