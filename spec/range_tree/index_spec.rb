require 'spec_helper'

describe Neo4jIndex::RangeTree::Index, :type => :transactional do

  describe "create" do
    it "create a new node" do
      index = Neo4jIndex::RangeTree::Index.new(:age => {:granularity => 0.1, :cluster => 10})
      index.indexed_props.should == %w[age]
      index.granularity(:age).should == 0.1
      index.cluster(:age).should == 10
    end
  end

  context "an empty index with one property" do
    before(:each) do
      @index = Neo4jIndex::RangeTree::Index.new(:age => {:granularity => 0.1, :cluster => 10})
    end

    describe ".insert" do
      it "create a leaf node" do
        data = Neo4j::Node.new(:property => 35)
        node = @index.insert(data)
      end

    end

  end
end
