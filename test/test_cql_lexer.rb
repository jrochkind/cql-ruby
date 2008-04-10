require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cql_ruby'

class TestCqlLexer < Test::Unit::TestCase
  def test_lexer
    cl = CqlRuby::CqlLexer.new
    cl.tokenize( "<a" )
    assert_equal cl.tokenize( 'one' ), ["one"]
    assert_equal cl.tokenize( 'one two'), ["one","two"]
    assert_equal cl.tokenize( '"a b c"'), ['"a b c"']
    assert_equal cl.tokenize( '"a ( b ) c"'), ['"a ( b ) c"']
    assert_raises( CqlRuby::CqlException ) { cl.tokenize( '"a ( b ) c') }
    
    c0 = CqlRuby::CqlLexer.new( '<a' )
    assert_equal( '<', c0.next_token )
    assert_equal( 'a', c0.next_token )
    
    c2 = CqlRuby::CqlLexer.new( 'abc 123 "a b c" x < <a and OR Not prox sortby >= <> <= ==' )
    c2.next_token
    assert_equal( CqlRuby::CqlLexer::TT_WORD, c2.token_type )
    assert( c2.word? )
    c2.next_token
    assert_equal( CqlRuby::CqlLexer::TT_NUMBER, c2.token_type )
    assert( c2.number? )
    assert_equal( '"', c2.next_token )
    assert_equal( 'a b c', c2.value )
    assert_equal( 'x', c2.next_token )
    assert_equal( '<',c2.next_token )
    assert_equal( '<', c2.next_token )
    assert_equal( 'a', c2.next_token )
    assert_equal( CqlRuby::CqlLexer::TT_AND , c2.next_token )
    assert( c2.and? )
    assert_equal( CqlRuby::CqlLexer::TT_OR, c2.next_token )
    assert( c2.or? )
    assert_equal( CqlRuby::CqlLexer::TT_NOT, c2.next_token )
    assert( c2.not? )
    assert_equal( CqlRuby::CqlLexer::TT_PROX, c2.next_token  )
    assert( c2.prox? )
    assert_equal( CqlRuby::CqlLexer::TT_SORTBY, c2.next_token )
    assert( c2.sortby? )
    assert_equal( CqlRuby::CqlLexer::TT_GE, c2.next_token )
    assert( c2.greater_than_or_equal? )
    assert_equal( CqlRuby::CqlLexer::TT_NE, c2.next_token )
    assert( c2.not_equal? )
    assert_equal( CqlRuby::CqlLexer::TT_LE, c2.next_token )
    assert( c2.less_than_or_equal? )
    assert_equal( CqlRuby::CqlLexer::TT_EQEQ, c2.next_token )
    assert( c2.double_equal? )
    assert_equal( CqlRuby::CqlLexer::TT_EOF, c2.next_token )
    assert( c2.eof? )
    
  end
end

