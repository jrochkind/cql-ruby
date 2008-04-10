#$:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
#
#Dir['map_by_method/**/*.rb'].sort.each { |lib| require lib }

  require File.dirname(__FILE__) + '/cql_ruby/cql_nodes'
  require File.dirname(__FILE__) + '/cql_ruby/cql_lexer'
  require File.dirname(__FILE__) + '/cql_ruby/cql_parser'
  require File.dirname(__FILE__) + '/cql_ruby/cql_to_solr'
