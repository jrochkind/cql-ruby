# This file adds #to_solr method to CqlRuby::CqlNodes, to
# convert parsed CQL to a query in the lucene-solr syntax.
# http://wiki.apache.org/solr/SolrQuerySyntax
#
# CQL version 1.2 spec was used to understand CQL semantics, although this
# will likely work for other CQL versions as well.  
#
# All indexes specified in CQL are mapped to Solr fields, assumed to exist, 
# with the same name as CQL index. Any 'context set' namespace prefixes
# on indexes are ignored, just the base name is mapped to solr field.

# The server-choice index specifications cql.anyindexes, cql.serverchoice,
# cql.keywords all map by default to no specified index (let
# solr use default from perhaps a solr 'df' param), but this can be changed
# with CqlRuby.to_solr_defaults[:default_index].  cql.allindexes maps
# by default to 'text', which can be changed with
# CqlRuby.to_solr_defaults[:all_index]
#
# Not all CQL can currently be converted to a solr query. If the CQL includes
# nodes that can not be converted, an exception will be raised.
#
# == CQL expressions that can be converted: ==  
#   * expressions using the following relations, which can be specified with "cql" prefix or without. 
#   ** adj
#   ** all
#   ** any
#   ** == (note, for typical tokenized solr fields, this will be the same as adj, which is not quite proper CQL semantics, but best we can do on an arbitrary solr field).
#   ** <> (note, for typical tokenized solr fields, won't have quite the right CQL semantics, instead of "not exactly equal to", it will be "does not contain the phrase").
#   ** >, <, <=, >=, within (note, solr range/comparison queries may or may not actually produce anything sensical depending on solr field definition, but CQL to_solr will translate into solr range syntax anyway and hope for the best. )
#   ** =, the server's choice relation, defaults to 'adj', but can be specified in CqlRuby.to_solr_defaults.
#   * CQL Boolean Operators AND, OR, and NOT. 
#
# == CQL expressions that can NOT be converted (at least in present version) ==
# And will raise exceptions if you try to call #to_solr on a CQL node which
# includes or has children that include the following:
# * PROX (boolean) operator.
# * cql.encloses relation
# * Any relation modifiers.
# * Any boolean (operator) modifiers.
# * sortBy
# * inline prefix map/prefix assignment specification. 
# * cql.resultsetid

# == TODO==
# * support modifiers on adj relation to map to solr '~' slop param?
# * change all tests to rspec instead of Test::Unit
# * implemented for acts_as_solr, either more flavors or more general (from chick, jrochkind isn't sure what this means)


module CqlRuby
  def self.to_solr_defaults
    @to_solr_params ||= {
        #What's our default relation for "=" server's choice relation? how about
        # adj.
      :default_relation => "cql.adj",
        # What's our default index for various server's choice index choices?
        # nil means don't specify an index, let solr take care of it.
        # Or you can specify one. 
      :default_index => nil,
        # What index should we use for cql.allIndexes? Again can be nil
        # meaning let the solr server use it's default.  
      :all_index => "text"
      }
  end
  

  

class CqlNode
  # Default, raise not supported, will be implemented by specific
  # classes where supported. 
  def to_solr    
    raise CqlException.new("#to_solr not supported for #{self.class}:  #{self.to_cql}")
  end
end



class CqlTermNode
 def to_solr
    relation = @relation.modifier_set.base            

    relation = CqlRuby.to_solr_defaults[:default_relation] if  relation == "="
    # If no prefix to relation, normalize to "cql"
    relation = "cql.#{relation}" unless relation.index(".") || ["<>", "<=", ">=", "<", ">", "=", "=="].include?(relation)

    
    # What's our default index for server choice indexes? Let's call it
    # "text".
    # Otherwise, remove the namespace/"context set" prefix.
    solr_field = case @index.downcase
                   when "cql.anyindexes", "cql.serverchoice", "cql.keywords"
                     CqlRuby.to_solr_defaults[:default_index]
                   when "cql.allindexes"
                     CqlRuby.to_solr_defaults[:all_index]
                   else
                     @index.gsub(/^[^.]*\./, "")
                 end
    
    raise CqlException.new("resultSet not supported") if @index.downcase == "cql.resultsetid"
    raise CqlException.new("relation modifiers not supported: #{@relation.modifier_set.to_cql}") if @relation.modifier_set.modifiers.length > 0

    if index.downcase == "cql.allrecords"
      #WARNING: Not sure if this will actually always work as intended, its
      # a bit odd. 
      return "[* TO *]"
    end

    
    negate = false
    
    value = 
    case relation
      # WARNING: Depending on how you've tokenized, <> and == semantics
      # may not be fully respected. For typical solr fields, will
      # match/exclude on partial matches too, not only complete matches. 
      when "<>"
        negate = true
        maybe_quote(@term)
      when "cql.adj", "==" then   maybe_quote(@term)                                
      when "cql.all" then '(' + @term.split(/\s/).collect{|a| '+'+a}.join(" ") + ')'          
      when "cql.any" then         '(' + @term.split(/\s/).join(" OR ") + ')'          
      when ">=" then              "[" + maybe_quote(@term) + " TO *]"          
      when ">" then               "{" + maybe_quote(@term) + " TO *}"          
      when "<=" then              "[* TO " + maybe_quote(@term) + "]"          
      when "<" then               "{* TO " + maybe_quote(@term) + "}"
      when "cql.within"
        bounds = @term.gsub('"', "").split(/\s/)
        raise CqlException.new("can not extract two bounding values from within relation term: #{@term}") unless bounds.length == 2

        "[" + maybe_quote(bounds[0]) + " TO " + maybe_quote(bounds[1]) + "]"                  
      else
        raise CqlException.new("relation not supported: #{relation}")
    end

    ret = ""
    ret += "-" if negate
    ret += "#{solr_field}:" if solr_field
    ret += value
    
    return ret     
  end
end

class CqlBooleanNode
  def to_solr
    "(#{@left_node.to_solr} #{@modifier_set.to_solr} #{@right_node.to_solr})"  
  end
end

class ModifierSet
  def to_solr
    raise CqlException.new("#to_solr not supported for PROX operator") if @base.upcase == "PROX"
    raise CqlException.new("#to_solr does not support boolean modifiers: #{to_cql}") if @modifiers.length != 0
    
    "#{@base.upcase}"
  end
end

end
