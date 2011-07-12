module CqlRuby
 
 # A generator that produces random CQL queries.
 # <P>
 # Why is that useful?  Mainly to produce test-cases for CQL parsers
 # (including the <TT>CQLParser</TT> class in this package): you can
 # generate a random search tree, render it to XCQL and remember the
 # result.  Then decompile the tree to CQL, feed the generated CQL to
 # the parser of your choice, and check that the XCQL it comes up with
 # is the same what you got from your initial rendering.
 # <P>
 # This code is based on the same grammar as the <TT>CQLParser</TT> class in
 # this distribution - there is a <TT>generate_<I>x</I>()</TT> method
 # for each grammar element <I>X</I>.
 #
 # @version $Id: CQLGenerator.java,v 1.9 2007/07/03 15:41:35 mike Exp $
 # @see   <A href="http://zing.z3950.org/cql/index.html"
 #            >http://zing.z3950.org/cql/index.html</A>
class CqlGenerator
  attr_accessor :params, :rnd, :debug_mode
  
  def initialize( params )
    @debug_mode = params[ :debug ] || false
    @params = params
    srand( params[ :seed ] ) if params and params[ :seed ]
  end
  
  def debug( s )
    puts( "DEBUG: #{s}" ) if @debug_mode
  end

  def generate_cql_query
    return generate_search_clause  unless maybe( :complex_query )
    
    node1 = generate_cql_query
    node2 = generate_search_clause
    
    if maybe( :proxOp ) 
      # TODO: generate proximity nodes
    else
      case rand( 3 )
      when 0 then return CqlAndNode.new( node1, node2, ModifierSet.new( "and" ) )
      when 1 then return CqlOrNode.new( node1, node2, ModifierSet.new( "or" ) )
      when 2 then return CqlNotNode.new( node1, node2, ModifierSet.new( "or" ) )
      end      
    end
    
    generate_search_clause
  end
  
  def generate_search_clause
    return generate_cql_query if maybe( :complex_clause )
    
    index = generate_index
    relation = generate_relation
    term = generate_term
    
    CqlTermNode.new( index, relation, term )
  end
  
  def generate_index
    if rand(2) == 0 
      case rand(3)
        when 0 then index = "dc.author"
        when 1 then index = "dc.title"
        when 2 then index = "dc.subject"
      end
    else
      case rand(4)
        when 0 then index = "bath.author"
        when 1 then index = "bath.title"
        when 2 then index = "bath.subject"
        when 3 then index = "foo>bar"
      end
    end
    index
  end
  
  def generate_relation
    base = generate_base_relation
    CqlRelation.new( base )
  end
  
  def generate_base_relation
    return "=" if maybe( :equals_relation )
    return generate_numeric_relation if maybe( :numeric_relation )
    case rand(3)
      when 0 then index = "exact"
      when 1 then index = "all"
      when 2 then index = "any"
    end
    index
  end
  
  def generate_term
    case rand(10)
      when 0 then return "cat"
      when 1 then return "\"cat\""
      when 2 then return "comp.os.linux"
      when 3 then return "xml:element"
      when 4 then return "<xml.element>"
      when 5 then return "prox/word/>=/5"
      when 6 then return ""
      when 7 then return "frog fish"
      when 8 then return "the complete dinosaur"
      when 9 then return "foo*bar"
    end
  end
  
  def generate_numeric_relation
    case rand(6)
      when 0 then return "<"
      when 1 then return ">"
      when 2 then return "<="
      when 3 then return ">="
      when 4 then return "<>"
      when 5 then return "="
    end
  end
  
  def maybe( key )
    probability = @params[ key ] || ".1"
    
    dice = rand
    threshold = probability.to_f
    res = dice < threshold
    
    debug( "dice=#{dice} vs #{threshold} = #{res.to_s}" )
    res
  end

end
end