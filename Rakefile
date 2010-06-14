require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "cql-ruby"
    gem.summary = %Q{ CQL Parser}
    gem.description = %Q{ CQL Parser, with serialization from cql node tree to cql, xcql, and solr query}
    gem.email = "cql_ruby@googlegroups.com"
    gem.homepage = "http://cql-ruby.rubyforge.org/"
    gem.rubyforge_project = "cql-ruby"
    gem.authors = ["Jonathan Rochkind", "Chick Markley"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    
    gem.files = FileList['lib/**/*.rb']
    gem.test_files = FileList['test/*.rb']
    
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cql-ruby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
