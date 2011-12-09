require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'benchmark'

require 'logger'

require 'neo4j-index'

Neo4j::Config[:logger_level] = Logger::ERROR
Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4jindex-rspec-db")

def rm_db_storage
  FileUtils.rm_rf Neo4j::Config[:storage_path]
  raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
end

def finish_tx
  return unless @tx
  @tx.success
  @tx.finish
  @tx = nil
end

def new_tx
  finish_tx if @tx
  @tx = Neo4j::Transaction.new
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


# set database storage location
RSpec::Matchers.define :have_bounding_box do |*bounding_box|

  match do |index_node|
    index_node[:value_min][0].should == bounding_box[0][0]
    index_node[:value_max][0].should == bounding_box[0][1]

    index_node[:value_min][1].should == bounding_box[1][0]
    index_node[:value_max][1].should == bounding_box[1][1]
  end
end

RSpec::Matchers.define :have_relationships do |*relationships|

  match do |node|
    @found = node._rels.map { |r| r.rel_type }.uniq
    # find the first one that is not included, if not found then all the given relationships exists
    @missing = relationships.map(&:to_s).to_a - @found
    @missing.empty?
  end

  failure_message_for_should do |_|
    "Missing relationships: #{@missing.join(', ')} found: #{@found.join(', ')}"
  end

  failure_message_for_should_not do |_|
    "Found relationships: #{@missing.join(', ')} in: #{@found.join(', ')}"
  end
end

RSpec::Matchers.define :have_outgoing do |relationship|
  chain :with_size do |size|
    @with_size = size
  end

  match do |node|
    rels = node.rels(:outgoing, relationship)
    if @with_size
      rels.size == @with_size
    else
      rels.size > 0
    end
  end
end

def rm_db_storage
  FileUtils.rm_rf Neo4j::Config[:storage_path]
  raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
end

def clean_db
  finish_tx
  Neo4j::Transaction.run do
    Neo4j._all_nodes.each { |n| n.del unless n.neo_id == 0 }
  end
end

RSpec.configure do |c|
  c.before(:all) { rm_db_storage unless Neo4j.running? }
  c.after(:all) { clean_db }

  c.before(:each, :type => :transactional) do
    new_tx
  end

  c.after(:each, :type => :transactional) do
    finish_tx
    Neo4j::Rails::Model.close_lucene_connections
  end

end


