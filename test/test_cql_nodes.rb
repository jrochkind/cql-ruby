require 'test/unit'
require 'rubygems'
require File.dirname(__FILE__) + '/../lib/cql_ruby'

class TestCqlNodes < Test::Unit::TestCase
  require 'builder'
  
  def test_node
    cn = CqlRuby::CqlNode.new
    
    cp = CqlRuby::CqlPrefix.new( 'bob', 'jones')
    
    es = <<-end_of_xml
<prefixes>
 <prefix>
  <name>bob</name>
  <identifier>jones</identifier>
 </prefix>
</prefixes>
end_of_xml

    xml = Builder::XmlMarkup.new(:indent => 1)
    assert_equal( es, cn.render_prefixes( xml, [cp] ) )


end

  def test_modifier_set

  end

  def test_cql_relation_node
    xml = Builder::XmlMarkup.new(:indent => 1)
    relation = CqlRuby::CqlRelation.new( "=" )
    
    assert_equal( "<relation>\n <value>=</value>\n</relation>\n", relation.to_xcql(xml) )
    assert_equal( "=", relation.to_cql )
    relation = CqlRuby::CqlRelation.new( "=" )
    
    xml = Builder::XmlMarkup.new(:indent => 1)
    assert_equal( "<relation>\n <value>=</value>\n</relation>\n", relation.to_xcql(xml) )
    assert_equal( "=", relation.to_cql )
  end
  
  def test_modifier
    modifier = CqlRuby::Modifier.new( "dog" )
    assert_equal( "dog", modifier.to_cql )
    modifier = CqlRuby::Modifier.new( "dog", "=", "cat" )
    assert_equal( "dog = cat", modifier.to_cql )
  end
  
  def test_modifier_set
        me = <<-end_of_modifier
<modifier>
 <type>a</type>
 <test>b</test>
 <value>c</value>
</modifier>
end_of_modifier

    m1 = CqlRuby::Modifier.new( 'a', 'b', 'c' )
    assert_equal( "a b c", m1.to_cql() )
    xml = Builder::XmlMarkup.new(:indent => 1)
    assert_equal( me, m1.to_xcql( xml, "test") )
    m1 = CqlRuby::Modifier.new( 'a' )
    xml = Builder::XmlMarkup.new(:indent => 1)
    assert_not_equal( me, m1.to_xcql( xml, "test") )
    
    ms = CqlRuby::ModifierSet.new( "base" )
    ms.add_modifier( "dog" )
    assert_equal( "base/dog", ms.to_cql )
    ms.add_modifier( "cat", "wont", "eat" )
    assert_equal("base/dog/cat wont eat",  ms.to_cql )
  end
  
  def test_cql_boolean_node
    n1 = CqlRuby::CqlNode.new
    n2 = CqlRuby::CqlNode.new
    ms = CqlRuby::ModifierSet.new( "=" )
    
    bn = CqlRuby::CqlBooleanNode.new( n1, n2, ms )
    assert_equal( "() = ()", bn.to_cql )
    # assert_equal( "() = ()", bn.to_xcql(0) )
  end
  
  def test_cql_term_node
    rel = CqlRuby::CqlRelation.new( "likes" )
    tn = CqlRuby::CqlTermNode.new( "dog", rel, "cat" )
    assert_equal( "dog likes cat", tn.to_cql )
    xml = Builder::XmlMarkup.new(:indent => 1)

    expected = <<end_of_expected
<searchClause>
 <index>dog</index>
 <relation>
  <value>likes</value>
 </relation>
 <term>cat</term>
</searchClause>
end_of_expected

    xml = Builder::XmlMarkup.new(:indent => 1)
    assert_equal( expected, tn.to_xcql(xml) )
  end
end
