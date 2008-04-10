require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cql_ruby'

class CqlToSolrTest < Test::Unit::TestCase
  def test_cql_to_solr
    parser = CqlRuby::CqlParser.new
    tree = parser.parse( "dc.title = dog" )
    assert_equal( "title:dog", tree.to_solr )
    tree = parser.parse( "cql.resultSetId = dog" )
    assert_raises( CqlRuby::CqlException ) { tree.to_solr }
    tree = parser.parse( "cql.allIndexes = dog" )
    assert_equal( "text:dog", tree.to_solr )
    tree = parser.parse( "dog AND cat" )
    assert_equal( "(dog) AND (cat)", tree.to_solr )
    tree = parser.parse( "dog and cat" )
    assert_equal( "(dog) AND (cat)", tree.to_solr )
    tree = parser.parse( "dc.title <> dog" )
    assert_equal( "-title:dog", tree.to_solr )
    
  end
end
