require 'spec_helper'

describe Neo4jIndex::RangeTree::Indexer, :type => :transactional do
  before(:each) do
    @node = {}
    @index = Neo4jIndex::RangeTree::Indexer.new(@node, :time)
  end

  #describe ".create_child" do
  #  pending
  #  before(:each) do
  #    @parent = Neo4j::Node.new(:level => 3)
  #    @child = subject.create_child(@parent, indexer, [4, 5, 6])
  #  end
  #
  #  it "decrease the level" do
  #    @child[:level].should == 2
  #  end
  #  it "sets the index values using the given indexer" do
  #    @child[:index_values].should == [7, 8, 9]
  #  end
  #
  #  it "creates a relationship between child and parent the index nodes" do
  #    @parent.should have_outgoing(:length_children).with_size(1)
  #  end
  #end

  describe ".value_for" do
    it "calculates the index value fixnum" do
      @index.origin = 1000
      @index.value_for(0, 0).should == 1000
      @index.value_for(1, 0).should == 995
      @index.value_for(2, 0).should == 950
    end
  end

  describe ".bounding_box_for" do
    it "should return the min and max values" do
      @index.origin = 100
      index_value = @index.index_value_for(0, 100)
      @index.bounding_box_for(0, index_value).should == [100, 101]

      index_value = @index.index_value_for(1, 100)
      @index.bounding_box_for(1, index_value).should == [95, 105]

      index_value = @index.index_value_for(2, 100)
      @index.bounding_box_for(2, index_value).should == [50, 150]
    end
  end

  describe ".index_value_for" do
    it "calculates the index value fixnum" do
      @index.origin = 1000
      @index.index_value_for(0, 1000).should == 0
      @index.index_value_for(1, 1000).should == 0
      @index.index_value_for(2, 1000).should == 0
    end


    it "boundary values" do
      @index.origin = 0
      @index.index_value_for(1, 4).should == 0
      @index.index_value_for(1, 5).should == 1
      @index.index_value_for(1, -5).should == 0
      @index.index_value_for(1, -6).should == -1
    end

    it "calculates the index value float" do
      @index.origin = 0
      @index.index_value_for(0, 1000.42).should == 1000
      @index.index_value_for(1, 1000.42).should == 100
      @index.index_value_for(2, 1000.42).should == 10
    end

  end


  describe ".create_parent" do
    before(:each) do
      @child = Neo4j::Node.new(:level => 3, :index_value => 42)
      @parent = @index.create_parent(@child)
    end

    it "increase the level" do
      @parent[:level].should == 4
    end
    it "sets the index values using the given indexer" do
      @parent[:index_value].should == 42
    end

    it "creates a relationship between child and parent the index nodes" do
      @parent.should have_outgoing(:_rangetree_time).with_size(1)
    end

    it "can find the parent" do
      @index.find_parent(@child).should == @parent
    end
  end

  describe ".include_value?" do
    it "should " do
      @index.origin = 0

      # index value 42 with level 0 gives 45-46 range
      i1 = @index.index_value_for(0, 42) # the index of the index_node
      #i2 = @index.index_value_for(0, 44) # the index of a different node
      @index.include_value?({:level => 0, :index_value => i1}, 44).should be_false

      # but parent should include it
      i1 = @index.index_value_for(1, 42) # the index of the index_node
      #i2 = @index.index_value_for(1, 44) # the index of a different node
      @index.include_value?({:level => 1, :index_value => i1}, 44).should be_true
    end
  end

  describe ".find_or_create_parent" do

    context "when there is no parent" do

      it "should create the parent if the current node does not contain the value" do
        @index.origin = 8
        child = Neo4j::Node.new(:level => 0, :index_value => 0) # first child
        parent = @index.find_or_create_parent({:time => 10}, child)
        @index.find_parent(child).should == parent
      end

      it "should create several parent index nodes until it gets one that includes the value" do
        @index.origin = 8
        child = Neo4j::Node.new(:level => 0, :index_value => 0)
        parent2 = @index.find_or_create_parent({:time => 50}, child) # get top parent
        parent1 = @index.find_children(parent2).first # # get child of that parent
        parent1.should_not be_nil
        @index.find_children(parent1).first.should == child # the child of that parent should be the child
      end

    end

    context "when there is a parent containing the value" do
      it "should find the parent" do
        child = Neo4j::Node.new(:level => 0, :index_value => 3)
        parent = @index.create_parent(child)
        @index.find_parent(child).should == parent
      end
    end


  end

end
