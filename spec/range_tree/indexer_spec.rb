require 'spec_helper'

describe Neo4jIndex::RangeTree::Indexer, :type => :transactional do
  before(:all) do
    @index = Neo4jIndex::RangeTree::Indexer.new(:time)
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

  describe ".index_value_for" do
    it "calculates the index value fixnum" do
      @index.index_value_for(0, 1000).should == 1000
      @index.value_for(0, 1000).should == 1000
      @index.index_value_for(1, 1000).should == 100
      @index.value_for(1, 100).should == 995
      @index.index_value_for(2, 1000).should == 10
      @index.value_for(2, 10).should == 950
    end


    it "boundary values" do
      @index.index_value_for(1, 4).should == 0
      @index.index_value_for(1, 5).should == 1
      @index.index_value_for(1, -5).should == 0
      @index.index_value_for(1, -6).should == -1

      puts "@index.bounding_box_for(1, 4)=#{@index.bounding_box_for(1, 4)}"
      puts "@index.bounding_box_for(1, 5)=#{@index.bounding_box_for(1, 5)}"
      puts "@index.bounding_box_for(2, 4)=#{@index.bounding_box_for(2, 4)}"
      puts "@index.bounding_box_for(2, 5)=#{@index.bounding_box_for(2, 5)}"

    end

    it "calculates the index value float" do
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

  describe ".find_or_create_parent" do
    context "when there is no parent" do
      it "should create the parent if the current node does not contain the value" do
        child = Neo4j::Node.new(:level => 0, :index_value => 3)
        puts "---"
        parent = @index.find_or_create_parent({:time => 8}, child)
        @index.find_parent(child).should == parent
      end
    end


  end

end