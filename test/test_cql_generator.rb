require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cql_ruby'
require File.dirname(__FILE__) + '/../lib/cql_ruby/cql_generator'

class TestCqlGenerator < Test::Unit::TestCase
  def test_generator
    params = {:seed => 1, :debug => false }
    
    parser = CqlRuby::CqlParser.new
    generator = CqlRuby::CqlGenerator.new( params )
    100.times do 
      tree = generator.generate_cql_query
      puts "tree built"
      puts tree.to_cql
      new_tree = parser.parse( tree.to_cql )
      assert( new_tree )
      assert( new_tree.to_solr )
      puts new_tree.to_solr
      # puts tree.to_xcql
    end
    puts "done"
  end
end
