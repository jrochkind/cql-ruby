# What

cql-ruby provides a common querly language (CQL) parser. CQL is a format frequently used in the library world. This parser was translated from the CQL-Java parser written by Mike Taylor available here http://zing.z3950.org/cql/java/

The parser builds a CQL parse tree suitable to serializing to various forms, built in are to_cql, to_xcql and to_solr (build a solr-lucene search query from cql)

# Installing

    sudo gem install cql_ruby

# The basics

You have been asked to provide SRU access to your website, so that the dynamic and exciting library community can find and promote access to and awareness of your rich content. You discover that in order to support SRU, dang! you need a CQL parser. Well now you have one.

# Demonstration of usage

  require 'cql_ruby'
  parser = CqlRuby::CqlParser.new
  puts parser.parse( 'dog and cat' ).to_solr

# Listserv

http://groups.google.com/group/cql_ruby

# Project

https://github.com/jrochkind/cql-ruby


# License

This code is free to use under the terms of the LGPL license.

# Contact

Comments are welcome. Best way to send them is to via the listserv

Chick Markley, from 9th April 2008
Jonathan Rochkind, from 14 June 2010

