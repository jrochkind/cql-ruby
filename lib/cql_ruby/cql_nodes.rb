module CqlRuby
  
class CqlNode
  require 'rubygems'
  require 'builder'
  def check_xml( xml )
    xml = Builder::XmlMarkup.new(:indent => 1) unless xml
#    (0..1).each {|x| puts x}
    xml
  end
  
  def initialize
    
  end
  
  def getResultSetName
    nil
  end
  
  # arguments kept for symmetry
  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    nil
  end

  def to_cql
    nil
  end
  
  def render_prefixes( xml=nil, prefixes=nil )
    return unless prefixes and prefixes.length > 0 
    
    xml = check_xml( xml )
    xml.prefixes do
      prefixes.each do |prefix|
        xml.prefix do
          xml.name( prefix.name )
          xml.identifier( prefix.identifier )
        end
      end
    end
  end
  
  def render_sortkeys( xml=nil, sortkeys=nil )
    return "" unless sortkeys and sortkeys.any?
    
    xml = check_xml( xml )
    xml.sortKeys do
      sortkeys.each do |key|
        key.sortkey_to_xcql( xml )
      end
    end
  end
end

class CqlPrefix
  attr_accessor :name, :identifier
  
  def initialize( name, identifier )
    super()
    @name = name
    @identifier = identifier
  end
end

class CqlPrefixNode < CqlNode
  attr_accessor :prefix, :subtree
  def initialize( name=nil, identifier=nil, new_subtree=nil )
    super()
    @prefix = CqlPrefix.new( name, identifier )
    @subtree = new_subtree
  end
  
  def to_cql
    if @prefix.name 
      ">#{@prefix.name}=\"#{@prefix.identifier}\" (#{@subtree.to_cql})"
    else
      ">\"#{@prefix.identifier}\" (#{@subtree.to_cql})"
    end
  end

  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    xml = check_xml( xml )
    tmp = []
    tmp = prefixes.dup if prefixes
    tmp << @prefix
    
    @subtree.to_xcql( xml, tmp, sortkeys )
  end
end

class Modifier < CqlNode
  attr_accessor :type, :comparison, :value
  
  def initialize( new_type, new_comparison=nil, new_value=nil)
    super()
    @type = new_type
    @comparison = new_comparison
    @value = new_value
  end
  
  def to_cql
    res = "#{@type}"
    res << " #{@comparison} #{@value}" if @value
    res
  end
  
  def to_xcql( xml=nil, relation_element="unknown_relation" )
    xml = check_xml( xml )
    xml.modifier do 
      xml.type( @type )
      if( @value )
        xml.tag!( relation_element, @comparison ) if @comparison
        xml.value( @value )
      end
    end
  end
end

class ModifierSet < CqlNode
  attr_accessor :base, :modifiers
  
  def initialize( base )
    # super
    @base = base.dup
    @modifiers = []
  end
  
  def add_modifier( type, comparison=nil, value=nil)
    modifiers << Modifier.new( type, comparison, value )
  end
  
  def to_cql
    res = @base.dup
    @modifiers.each do |m| 
      res << "/#{m.to_cql}"
    end
    res
  end
  
  def to_xcql( xml=nil, top_level_element="unknowElement" )
    xml = check_xml( xml )
    underlying_to_xcql( xml, top_level_element, "value" )
  end
  
  def sortkey_to_xcql( xml=nil )
    xml = check_xml( xml )
    underlying_to_xcql( xml, "key", "index" )
  end
  
  def underlying_to_xcql( xml, top_level_element, value_element )
    xml.tag!( top_level_element ) do
      xml.tag!( value_element, @base )
      if @modifiers.any?
        xml.modifiers do
          @modifiers.each { |modifier| modifier.to_xcql( xml, "comparison" ) }
        end
      end
    end
  end
end

class CqlBooleanNode < CqlNode
  attr_accessor :left_node, :right_node, :modifier_set
  
  def initialize( left_node, right_node, modifier_set )
    super()
    @left_node = left_node.dup
    @right_node = right_node.dup
    @modifier_set = modifier_set || ModifierSet.new( "=" )
  end
  
  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    xml = check_xml( xml )
    xml.triple do
      render_prefixes( xml, prefixes )
      modifier_set.to_xcql( xml, "boolean" )
      xml.leftOperand do
        left_node.to_xcql( xml )
      end
      xml.rightOperand do
        right_node.to_xcql( xml )
      end
      render_sortkeys( xml, sortkeys )
    end
  end

  def to_cql
    "(#{@left_node.to_cql}) #{@modifier_set.to_cql} (#{@right_node.to_cql})"
  end
end


 # Represents a terminal node in a CQL parse-tree.
 # A term node consists of the term String itself, together with,
 # optionally, an index string and a relation.  Neither or both of
 # these must be provided - you can't have an index without a
 # relation or vice versa.

class CqlTermNode < CqlNode
  attr_accessor :index, :relation, :term
  def initialize( index, relation, term )
    super()
    
    @index = index.dup
    @relation = relation.dup
    @term = term.dup
  end
  
  def result_set_index?( qual )
    /(srw|cql).resultSet(|Id|Name|SetName)/ =~ qual
  end
  
  def result_set_name
    return term if result_set_index?( @index )
    nil
  end
  
  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    xml = check_xml( xml )
    
    xml.searchClause do
      render_prefixes( xml, prefixes )
      xml.index( @index )
      @relation.to_xcql( xml )
      xml.term( @term )
      render_sortkeys( xml, sortkeys )
    end
  end
  
  def to_cql
    quoted_index = maybe_quote( @index )
    quoted_term = maybe_quote( @term )
    res = quoted_term
    
    if @index && /(srw|cql)\.serverChoice/i !~ @index
      res = "#{quoted_index} #{@relation.to_cql} #{quoted_term}"
    end
    res
  end
  
  def maybe_quote( s )
    if s == "" || s =~ /[" \t=<>()\/]/
      return "\"#{s.gsub( /"/, "\\\"" )}\""
    end
    s
  end
end

class CqlAndNode < CqlBooleanNode
  def initialize( left_node, right_node, modifier_set )
    super( left_node, right_node, modifier_set )
  end
end
class CqlOrNode < CqlBooleanNode
  def initialize( left_node, right_node, modifier_set )
    super( left_node, right_node, modifier_set )
  end
end
class CqlNotNode < CqlBooleanNode
  def initialize( left_node, right_node, modifier_set )
    super( left_node, right_node, modifier_set )
  end
end
class CqlProxNode < CqlBooleanNode
  def initialize( left_node, right_node, modifier_set )
    super( left_node, right_node, modifier_set )
  end
end

class CqlRelation < CqlNode
  attr_accessor :modifier_set
  
  def initialize( base )
    super()
    @modifier_set = ModifierSet.new( base )
  end
  
  def set_modifiers( ms )
    @modifier_set = ms
  end
  
  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    raise CqlException,  "CqlRelation.to_xcql called with no relation" if sortkeys 
    xml = check_xml( xml )
    @modifier_set.to_xcql( xml, "relation" )
  end
  
  def to_cql
    @modifier_set.to_cql()
  end
end

class CqlSortNode < CqlNode
  attr_accessor :subtree, :keys
  
  def initialize( subtree )
    super()
    @subtree = subtree
    @keys = []
  end
  
  def add_sort_index( key )
    @keys << key
  end
  
  def to_xcql( xml=nil, prefixes=nil, sortkeys=nil )
    raise CqlException,  "CqlSortNode.to_xcql called with sortkeys" if sortkeys and sortkeys.any?

    xml = check_xml( xml )
    return @subtree.to_xcql( xml, prefixes, @keys )
  end
  
  def to_cql
    buf = @subtree.to_cql
    if @keys.any?
      buf << " sortby "
      @keys.each do |key|
        buf << " #{key.to_cql}"
      end
    end
    buf
  end
end

class CqlException < RuntimeError
end

end