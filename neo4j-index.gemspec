lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neo4j-index/version'

#6009
Gem::Specification.new do |s|
  s.name     = "neo4j-index"
  s.version  = Neo4jIndex::VERSION
  s.platform = 'java'
  s.required_ruby_version = ">= 1.8.7"

  s.authors  = "Andreas Ronge"
  s.email    = 'andreas.ronge@gmail.com'
  s.homepage = "https://github.com/organizations/AmanziTel"
  s.rubyforge_project = 'neo4j-index'
  s.summary = "A index for the neo4j graph database"
  s.description = <<-EOF
  Creates a search tree in the graph db.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{lib}/**/*") + %w(Gemfile neo4j-index.gemspec)
  s.has_rdoc = true
  #s.extra_rdoc_files = %w( README.rdoc )
  s.rdoc_options = ["--quiet", "--title", "Neo4jIndex", "--line-numbers", "--inline-source"]

  s.add_dependency('neo4j', ">= 1.2")
end
