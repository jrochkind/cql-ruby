module CqlRuby
  
# This set of of overrides to the CqlRuby::CqlNodes provides to_solr methods, where not
# specified for a given node the CqlNode.to_solr method will be used
# TODO: SOLR can cover much more functionality of CQL than is captured here
# TODO: implemented for acts_as_solr, either more flavors or more general

class CqlNode
  def to_solr
    quoted_index = maybe_quote( @index )
    quoted_term = maybe_quote( @term )
    relation_prefix = @relation.to_solr
    case quoted_index
      when 'cql.resultSetId': raise CqlException, "resultSet not supported"
      when 'cql.allRecords': "[* TO *]"
      when 'cql.allIndexes': "#{relation_prefix}text:#{quoted_term}"
      when 'cql.anyIndexes': "#{relation_prefix}text:#{quoted_term}"
      when 'cql.serverChoice': "#{relation_prefix}#{quoted_term}"
    else
      quoted_index.gsub!( /(dc|bath)\./, "" )
      "#{relation_prefix}#{quoted_index}:#{quoted_term}"
    end
    
  end
end

# looks like we are just handling not equal now
class CqlRelation
  def to_solr
    ms = @modifier_set.to_solr
    if ms == " <> "
      return "-"
    end
    ""
  end
end

class CqlTermNode
#  def to_solr
#    "arghh"
#  end
end

class CqlBooleanNode
  def to_solr
    "(#{@left_node.to_solr})#{@modifier_set.to_solr}(#{@right_node.to_solr})"  
  end
end

class ModifierSet
  def to_solr
    raise CqlException, "PROX not supported" if @base.upcase == "prox"
    " #{@base.upcase} "
  end
end

end