# $Id: CQLNode.java,v 1.26 2007/07/03 13:36:03 mike Exp $

module CqlRuby 

# Compiles CQL strings into parse trees of CQLNode subtypes.
#
# @see   <A href="http://zing.z3950.org/cql/index.html">http://zing.z3950.org/cql/index.html</A>
class CqlParser
  attr_accessor :lexer, :compat, :debug, :lex_debug
  
  V1POINT1 = 12368;
  V1POINT2 = 12369;
  V1POINT1SORT = 12370;
  
  def initialize( set_compat = CqlParser::V1POINT2 )
    @compat = set_compat
    @debug = false
    @lex_debug = false
  end
  
  def parse( s )
    @lexer = CqlLexer.new( s, @lex_debug )
    log( "starting parser" )
    @lexer.next_token
    
    root = parse_top_level_prefixes( "cql.serverChoice", CqlRelation.new( @compat == CqlParser::V1POINT2 ? "=" :  "scr" ))
    raise CqlException,  "junk after end: #{@lexer.render}" unless @lexer.eof?
    
    root
  end
  
  def parse_top_level_prefixes( index, relation )
    log "topl level prefix mapping"
    
    if @lexer.token_type == '>'
      return parse_prefix( index, relation, true )
    end
    
    node = parse_query( index, relation )
    if ( @compat == V1POINT2 || @compat == V1POINT1SORT ) && @lexer.token_type == CqlLexer::TT_SORTBY
      match( @lexer.token_type )
      log "sortspec"
      
      sortnode = CqlSortNode.new( node )
      until @lexer.eof?
        sortindex = match_symbol( "sort index" )
        ms = gather_modifiers( sortindex )
        sortnode.add_sort_index( ms )
      end
      
      if sortnode.keys.empty?
        raise CqlException,  "parse exception: no sort keys"
      end
      node = sortnode
    end
    node
  end
  
  def parse_query( index, relation )
    log "parse_query"
    
    term = parse_term( index, relation )
    until @lexer.eof? or @lexer.token_type == ')' or @lexer.token_type == CqlLexer::TT_SORTBY
      if [CqlLexer::TT_AND,CqlLexer::TT_OR,CqlLexer::TT_NOT,CqlLexer::TT_PROX].include?( @lexer.token_type)
        token_type = @lexer.token_type
        value = @lexer.value
        match( token_type )
        ms = gather_modifiers( value )
        term2 = parse_term( index, relation )
        term = case token_type
                when CqlLexer::TT_AND: CqlAndNode.new( term, term2, ms )
                when CqlLexer::TT_OR: CqlOrNode.new( term, term2, ms )
                when CqlLexer::TT_NOT: CqlNotNode.new( term, term2, ms )
                when CqlLexer::TT_PROX: CqlProxNode.new( term, term2, ms )
              end
        
      else
        raise CqlException,  "parse exception: expect boolean, got: #{@lexer.render}"
      end
    end
    term
  end
  
  def gather_modifiers( base )
    log "gather modifiers"
    
    ms = ModifierSet.new( base )
    until @lexer.token_type != '/'
      match( '/' )
      raise CqlException,  "parse error: expected modifier, got: #{@lexer.render}" unless  @lexer.word?
      type = @lexer.value.downcase
      match( @lexer.token_type )
      if not relation?
        ms.add_modifier( type )
      else
        comparison = @lexer.render( @lexer.token_type, false )
        match( @lexer.token_type )
        value = match_symbol( "modifier value" )
        ms.add_modifier( type, comparison, value )
      end
    end
    ms
  end
  
  def parse_term( index, relation )
    log "parse_term"
    
    while true
      if @lexer.token_type == '('
        log "parenthesised form"
        match( '(' )
        expr = parse_query( index, relation )
        match( ')' )
        return expr
      elsif @lexer.token_type == '>'
        return parse_prefix( index, relation, false )
      end
      
      log "non-parenthesized form"
      word = match_symbol( "index or term" )
      break if not relation? and not @lexer.word? 
      
      index = word
      relstr = @lexer.word? ? @lexer.value : @lexer.render( @lexer.token_type, false )
      relation = CqlRelation.new( relstr )
      match( @lexer.token_type )
      ms = gather_modifiers( relstr )
      relation.set_modifiers( ms )
      log( "index='#{index}', relation='#{relation.to_cql}'")
    end
    
    node = CqlTermNode.new( index, relation, word )
    log( "made term node #{node.to_cql}" )
    node
  end
  
  def relation?
    log "relation?: checking token_type=#{@lexer.token_type} (#{@lexer.render})"
    ['<','>','=',CqlLexer::TT_LE,CqlLexer::TT_GE,CqlLexer::TT_NE,CqlLexer::TT_EQEQ].include?(@lexer.token_type)
  end
  
  def match( token )
    if @lexer.token_type != token
      raise CqlException,  "parse exception expected: #{@lexer.render( token, true )}, got: #{@lexer.render(token)}"
    end
    @lexer.next_token
  end
  
  def match_symbol( symbol_type )
    log "in match_symbol(#{symbol_type})"
    
    if CqlLexer.symbol_tokens.include?( @lexer.token_type )
      symbol = @lexer.value
      match( @lexer.token_type )
      return symbol
    end
    raise CqlException, "parse exception match_symbol, expected: #{symbol_type}, got: #{@lexer.render()}"
  end

  def parse_prefix( index, relation, top_level )
    log "prefix mapping"
    
    match( '>' )
    name = nil
    identifier = match_symbol( "prefix-name" )
    if @lexer.token_type == '='
      match('=')
      name = identifier
      identifier = match_symbol( "prefix-identifier" )
    end
    node = top_level ? 
      parse_top_level_prefixes( index, relation ) :
      parse_query( index, relation )
    
    CqlPrefixNode.new( name, identifier, node )
  end
  
  def log( s )
    puts "log: #{s}" if @debug
  end
end

end