require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cql_ruby'

class CqlToSolrTest < Test::Unit::TestCase
  @@parser = CqlRuby::CqlParser.new
  
  def test_boolean
    assert_to_solr_eq("dog or cat and mammal", '((dog OR cat) AND mammal)')
    assert_to_solr_eq("dog or (cat and mammal)", '(dog OR (cat AND mammal))')
    assert_to_solr_eq('dog not cat', "(dog NOT cat)")
  end

  def test_unsupported_cql
    assert_can_not_to_solr("cql.resultSetId = dog")
    assert_can_not_to_solr("field = value PROX field2 = value2")
    assert_can_not_to_solr("something cql.encloses 2000")
    assert_can_not_to_solr("field = dog sortBy someField")
    assert_can_not_to_solr("field unknownrelation value")

    assert_can_not_to_solr("cat or/rel.combine=sum dog")
    assert_can_not_to_solr("title any/relevant fish")

    assert_can_not_to_solr('> dc = "http://deepcustard.org/" dc.custardDepth > 10')
  end

  def test_rel_adj
    assert_to_solr_eq('column cql.adj "one two three"', 'column:"one two three"')
  end

  def test_rel_eq
    # '==' is same as 'adj', best we can do
    assert_to_solr_eq('column == "one two three"', @@parser.parse('column adj "one two three"').to_solr)
  end

  def test_rel_any
    assert_to_solr_eq('column cql.any "one_term two_term three_term"', 'column:(one_term OR two_term OR three_term)')
  end

  # For some reason these particular tokens caaused a bug
  def test_any_number_tokens
    assert_to_solr_eq('number_field cql.any "bib_1 bib_2"', 'number_field:(bib_1 OR bib_2)')
  end


  def test_rel_all
    assert_to_solr_eq('column cql.all "one two three"', 'column:(+one +two +three)')
  end

  
  def test_rel_not
    # Depending on solr schema, this will really map to "does not include phrase", not "does not exactly equal", best we can do. 
    assert_to_solr_eq('column <> "one two three"', '-column:"one two three"')
  end

  def test_rel_default
    # '=' defaults to adj
    assert_to_solr_eq('column = value', @@parser.parse("column adj value").to_solr)

    # unless we set it otherwise
    with_cql_default(:default_relation, "any") do
      assert_to_solr_eq('column = value', @@parser.parse("column any value").to_solr)
    end
  end

  def test_range
    assert_to_solr_eq('column > 100', 'column:{100 TO *}')
    assert_to_solr_eq('column < 100', 'column:{* TO 100}')
    assert_to_solr_eq('column >= 100', 'column:[100 TO *]')
    assert_to_solr_eq('column <= 100', 'column:[* TO 100]')
    assert_to_solr_eq('column cql.within "100 200"', 'column:[100 TO 200]')
  end

  def test_drop_index_prefix
    assert_to_solr_eq("dc.title = frog", @@parser.parse("title = frog").to_solr)
  end

  def test_specified_default_index    
    with_cql_default(:default_index, "default_index") do    
      ["cql.anyindexes", "cql.serverchoice", "cql.keywords"].each do |index|
        assert_to_solr_eq("#{index} = val", @@parser.parse("default_index = val").to_solr)
      end
    end            
  end

  def test_all_index
    assert_to_solr_eq("cql.allindexes = val", @@parser.parse("text = val").to_solr)

    with_cql_default(:all_index, "my_all_index") do
      assert_to_solr_eq("cql.allindexes = val", @@parser.parse("my_all_index = val").to_solr)
    end        
  end
  
  def test_escapes_terms
    assert_to_solr_eq('text = ab[]cd', 'text:"ab[]cd"')
    
    assert_to_solr_eq('text = "one\'s \" two"', 'text:"one\'s \" two"')
  end

#############
# Helpers
##############
  
  def assert_to_solr_eq(cql, should_solr)
    solr = @@parser.parse(cql).to_solr
    assert_equal(should_solr, solr)
  end
  
  def assert_can_not_to_solr(string)
    assert_raises(CqlRuby::CqlException) do 
      CqlRuby::CqlParser.new.parse(string).to_solr
    end
  end

  def with_cql_default(key, value)
    old_value = CqlRuby.to_solr_defaults[key]
    CqlRuby.to_solr_defaults[key] = value
    begin
      yield
    ensure
      CqlRuby.to_solr_defaults[key] = old_value
    end    
  end
end
