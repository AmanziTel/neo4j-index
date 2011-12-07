require 'spec_helper'

describe Neo4jIndex::RangeTree, :type => :transactional do

  class Person
    include Neo4j::NodeMixin
    include Neo4jIndex::RangeTree

    property :age
    index :age, :type => :range_tree
  end

  it "should add a new indexer"
end