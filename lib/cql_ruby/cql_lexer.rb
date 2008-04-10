module CqlRuby
  
# This is derived from java based a semi-trivial subclass for java.io.StreamTokenizer that:
#  * Includes a render() method
#  * Knows about the multi-character tokens "<=", ">=" and "<>"
#  * Recognises a set of keywords as tokens in their own right
#  * Includes some primitive debugging-output facilities
# It's used only by CQLParser

class CqlLexer
  attr_accessor :tokenizer, :simple_tokens, :index, :token_type, :value

  TT_EOF        = 1
  TT_EOL        = 2
  TT_NUMBER     = 3
  TT_WORD       = 4
  TT_LE        = 1000   # The "<=" relation
  TT_GE        = 1001   # The ">=" relation
  TT_NE        = 1002   # The "<>" relation
  TT_EQEQ      = 1003   # The "==" relation
  TT_AND       = 1004   # The "and" boolean
  TT_OR        = 1005   # The "or" boolean
  TT_NOT       = 1006   # The "not" boolean
  TT_PROX      = 1007   # The "prox" boolean
  TT_SORTBY     = 1008  # The "sortby" operator
  
  @@keywords = { "and" => CqlLexer::TT_AND, "or" => CqlLexer::TT_OR, "not" => CqlLexer::TT_NOT,
                 "prox" => CqlLexer::TT_PROX, "sortby" => CqlLexer::TT_SORTBY}
  @@symbol_tokens = @@keywords.values + [CqlLexer::TT_WORD,CqlLexer::TT_NUMBER,'"']

  @@ordinary_chars = /[=<>\/()]/
  @@re_any_token_start = /[\w(\)<>\/="*]/
  @@re_string_end = /[ \t(\)<>\/="]/
  
  def initialize( s="", debug=false )
    debug
    @simple_tokens = tokenize( s )
    @index = -1
  end
  
  def CqlLexer.symbol_tokens
    @@symbol_tokens
  end
  
  def find_string_end( s, position )
    s.index( @@re_string_end, position) || s.length
  end
  
  def find_quoted_string_end( s, position )
    is_backslashed = false
    for i in position+1..s.length
      if s[i..i] == '\\'
        is_backslashed = ! is_backslashed
      else
        if s[i..i] == '"' and not is_backslashed
          return i + 1
        end
        is_backslashed = false
      end
    end 
    raise CqlException,  "unterminated quoted string at position #{position} in '#{s}'"
    return s.length
  end
  
  def tokenize( cql_string )
    position = 0
    previous_backslash = false
    length = cql_string.length
    
    @tokens = []
    while position < length
      token_begin = cql_string.index( @@re_any_token_start, position )
      break unless token_begin
      

      case cql_string[token_begin..token_begin]
        when @@ordinary_chars
          token_end = token_begin+1
        when /[\w*]/
          token_end = find_string_end( cql_string, token_begin )
        when '"'
          token_end = find_quoted_string_end( cql_string, token_begin )
        else
          token_end = token_begin+1
      end
      
      @tokens << cql_string[token_begin..token_end-1]
      position = token_end
    end
    
    # puts "tokens=#{@tokens.inspect}"
    @tokens
  end
  
  def next_token
    underlying_next_token
    return CqlLexer::TT_EOF if eof? or eol?
    
    if @token_type == '<'
      underlying_next_token
      if @token_type == '=' 
        @token_type = CqlLexer::TT_LE
      elsif @token_type == ">"
        @token_type = CqlLexer::TT_NE
      else
        push_back
        @token_type = '<'
      end
    elsif @token_type == '>'
      underlying_next_token
      if @token_type == '=' 
        @token_type = CqlLexer::TT_GE
      else
        push_back
        @token_type = '>'
      end
    elsif @token_type == '='
      underlying_next_token
      if @token_type == '=' 
        @token_type = CqlLexer::TT_EQEQ
      else
        push_back
        @token_type = '='
      end
    end
    @token_type
  end

  def underlying_next_token
    @index += 1
    if @index >= @simple_tokens.length
      @token_type = CqlLexer::TT_EOF
      @value = nil
      return
    end
    @value = @simple_tokens[ @index ]
    if /[0-9]+/ =~ @value
      @token_type = CqlLexer::TT_NUMBER
    elsif @value.length > 1
      if @value.slice(0..0) == '"'
        @token_type = '"'
        @value = @value.slice(1..-2)
      else
        @token_type = @@keywords[ @value.downcase ] || CqlLexer::TT_WORD
      end
    else
      @token_type = @value
    end
  end
  
  def push_back
    @index -= 1
  end
  
  def render( token=nil, quote_chars=true )
    token = @token_type unless token
    case token
      when CqlLexer::TT_EOF: "EOF"
      when CqlLexer::TT_NUMBER: @value
      when CqlLexer::TT_WORD: "word:#{@value}"
      when "'": "string:\"#{@value}\""
      when CqlLexer::TT_LE: "<="
      when CqlLexer::TT_GE: ">="
      when CqlLexer::TT_NE: "<>"
      when CqlLexer::TT_EQEQ: "=="
      when CqlLexer::TT_EOF: "EOF"
    else
      if @@keywords.has_value?( @value )
        @value
      else
        if quote_chars 
          "'#{token}'"
        else
          token
        end
      end
    end
  end
  
  def eof?
    @token_type == CqlLexer::TT_EOF
  end
  def eol?
    @token_type == CqlLexer::TT_EOL
  end
  def number?
    @token_type == CqlLexer::TT_NUMBER
  end
  def word?
    @token_type == CqlLexer::TT_WORD
  end
  def less_than_or_equal?
    @token_type == CqlLexer::TT_LE
  end
  def greater_than_or_equal?
    @token_type == CqlLexer::TT_GE
  end
  def double_equal?
    @token_type == CqlLexer::TT_EQEQ
  end
  def not_equal?
    @token_type == CqlLexer::TT_NE
  end
  def not?
    @token_type == CqlLexer::TT_NOT
  end
  def and?
    @token_type == CqlLexer::TT_AND
  end
  def or?
    @token_type == CqlLexer::TT_OR
  end
    def prox?
    @token_type == CqlLexer::TT_PROX
  end
  def sortby?
    @token_type == CqlLexer::TT_SORTBY
  end

end 
end