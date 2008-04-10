require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cql_ruby'

class TestCqlParser < Test::Unit::TestCase
  def test_coverage
    parser = CqlRuby::CqlParser.new
    lines = IO.readlines( File.dirname(__FILE__) + '/fixtures/sample_queries.txt' )
    lines.each do |line|
      next if /^\s*#/ =~ line
      begin
      tree = parser.parse( line )
      puts "in=#{line} out=#{tree.to_cql}" if tree
      rescue Exception
        puts "exception: line=#{line} error=#{$!}"
      end
    end
  end
  
  def test_parser
    parser = CqlRuby::CqlParser.new
    parser.debug = false
    
    
    tree = parser.parse( ">fox=lynx dog = cat" )
    assert_equal( '>fox="lynx" (dog = cat)', tree.to_cql )
    
    assert_raises( CqlRuby::CqlException ) { parser.parse( "dog sortby" ) }
    
    tree = parser.parse( "> dog cat" )
    assert_equal( '>"dog" (cat)', tree.to_cql )
    
    tree = parser.parse( "dc.title < cat" )
    assert_equal( 'dc.title < cat', tree.to_cql )
    
    tree = parser.parse( "dog ** fish" )
    assert_equal( 'dog ** fish', tree.to_cql )
    
    tree = parser.parse( "dog prox fish" )
    assert_equal( '(dog) prox (fish)', tree.to_cql )
    
    tree = parser.parse( "dog not fish" )
    assert_equal( '(dog) not (fish)', tree.to_cql )
    
    assert_raises( CqlRuby::CqlException ) { parser.parse( 'abc = "def' ) }

    tree = parser.parse( "au=(Kerninghan or Ritchie) and ti=Unix" )
    assert_equal( '((au = Kerninghan) or (au = Ritchie)) and (ti = Unix)', tree.to_cql )
    
    query = 'cql.resultSetId = "resultA" and cql.resultSetId = "resultB"'
    result = '(cql.resultSetId = resulta) and (cql.resultSetId = resultb)'
    tree = parser.parse( query )
    assert_equal( result.downcase, tree.to_cql.downcase )

    query = 'dc.title any/relevant/rel.CORI "cat fish"'
    tree = parser.parse( query )
    assert_equal( query.downcase, tree.to_cql )

    query = 'cql.resultSetId = "resultA" or cql.resultSetId = "resultB"'
    tree = parser.parse( query )
    result = '(cql.resultSetId = resultA) or (cql.resultSetId = resultB)'
    assert_equal( result, tree.to_cql )

    query = 'dc.title any/relevant/rel.CORI "cat fish" sortBy dc.date/sort.ascending'
    tree = parser.parse( query )
    puts "tree=#{tree.to_cql}="
    assert_equal( 'dc.title any/relevant/rel.cori "cat fish" sortby  dc.date/sort.ascending', tree.to_cql )

    query = 'cql.resultSetId = "resultA" or cql.resultSetId = "resultB"'
    result = '(cql.resultSetId = resulta) or (cql.resultSetId = resultb)'
    tree = parser.parse( query )
    assert_equal( result.downcase, tree.to_cql.downcase )

    query = 'author = "smith"'
    result = 'author = smith'
    tree = parser.parse( query )
    result1 = tree.to_cql
    assert_equal( result, result1 )
    tree = parser.parse( result1 )
    result2 = tree.to_cql
    assert_equal( result1, result2 )

    result = <<end_of_result
<searchClause>
 <index>
  dc.title
 </index>
 <relation>
  <value>
   any
  </value>
  <modifiers>
   <modifier>
    <type>relevant</type>
   </modifier>
   <modifier>
    <type>rel.cori</type>
   </modifier>
  </modifiers>
 </relation>
 <term>
  cat fish
 </term>
</searchClause>
end_of_result

    tree = parser.parse( 'dc.title any/relevant/rel.CORI "cat fish"')
    result.gsub!( /\s+/, '' )
    tree_string = tree.to_xcql
    tree_string.gsub!( /\s+/, '' )
    assert_equal( result, tree_string )
    
  end
end
