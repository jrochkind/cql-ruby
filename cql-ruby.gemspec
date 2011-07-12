# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cql-ruby}
  s.version = "0.8.1"

  s.authors = ["Jonathan Rochkind", "Chick Markley"]
  s.summary = 'CQL Parser'
  s.description = %q{ CQL Parser, with serialization from cql node tree to cql, xcql, and solr query}
  s.email = %q{cql_ruby@googlegroups.com}
  s.extra_rdoc_files = [
    "README.txt"
  ]
  s.files = [
    "lib/cql_ruby.rb",
     "lib/cql_ruby/cql_generator.rb",
     "lib/cql_ruby/cql_lexer.rb",
     "lib/cql_ruby/cql_nodes.rb",
     "lib/cql_ruby/cql_parser.rb",
     "lib/cql_ruby/cql_to_solr.rb",
     "lib/cql_ruby/version.rb"
  ]
  s.homepage = %q{http://cql-ruby.rubyforge.org/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{cql-ruby}
  s.test_files = [
    "test/test_cql_parser.rb",
     "test/test_cql_nodes.rb",
     "test/test_cql_generator.rb",
     "test/test_cql_lexer.rb",
     "test/test_cql_ruby.rb",
     "test/test_helper.rb",
     "test/helper.rb",
     "test/test_cql_to_solr.rb"
  ]

end

