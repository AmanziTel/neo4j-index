require 'spec_helper'

describe Neo4jIndex::RangeTree::IndexNode, :type => :transactional do
  describe ".create_raw" do
    it "creates a node" do
      node = subject.create_raw([1, 2, 3], 4)
      node[:index_values].should == [1, 2, 3]
      node[:level].should == 4
    end
  end

  describe ".create_child" do
    before(:each) do
      @parent = Neo4j::Node.new(:level => 3)
      indexer = mock()
      indexer.should_receive(:relationship).and_return(:length_children)
      indexer.should_receive(:calculate_index_values).with(2, [4, 5, 6]).and_return([7, 8, 9])
      @child = subject.create_child(@parent, indexer, [4, 5, 6])
    end

    it "decrease the level" do
      @child[:level].should == 2
    end
    it "sets the index values using the given indexer" do
      @child[:index_values].should == [7, 8, 9]
    end

    it "creates a relationship between child and parent the index nodes" do
      @parent.should have_outgoing(:length_children).with_size(1)
    end
  end

  describe ".create_parent" do
    before(:each) do
      @child = Neo4j::Node.new(:level => 3, :index_values => [1,3,5])
      indexer = mock()
      indexer.should_receive(:relationship).and_return(:length_children)
      @parent = subject.create_parent(@child, indexer)
    end

    it "increase the level" do
      @parent[:level].should == 4
    end
    it "sets the index values using the given indexer" do
      @parent[:index_values].should == [1,3,5]
    end

    it "creates a relationship between child and parent the index nodes" do
      @parent.should have_outgoing(:length_children).with_size(1)
    end
  end

end