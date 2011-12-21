require 'spec_helper'

describe Neo4jIndex::RangeTree::Index, :type => :transactional do

  let(:source_node) { Neo4j::Node.new }

  let(:range_tree_two_dim) do
    Neo4jIndex::RangeTree::Index.new(source_node, :age => {:granularity => 1, :cluster => 10}, :size => {:granularity => 1, :cluster => 10})
  end


  describe "create" do
    subject { range_tree_two_dim }

    its(:indexed_props) { should =~ [:age, :size]}

  end


  describe "insert" do
    context "when empty" do
      before do
        range_tree_two_dim.insert({:age => 42, :size => 10})
      end
       it "create a first index node" do
         range_tree_two_dim.root.should_not be_nil
         range_tree_two_dim.root[:l_age].should == 0
         range_tree_two_dim.root[:l_size].should == 0
         range_tree_two_dim.root[:i_age].should == 0
         range_tree_two_dim.root[:i_size].should == 0
       end

      it "sets the source_node" do
        range_tree_two_dim.source_node.outgoing(:range_tree).should include(range_tree_two_dim.root)
      end
    end

    context "when there is one index node" do
      before do
        range_tree_two_dim.insert(:age => 5, :size => 0)
      end

      it "can create one parent" do
        range_tree_two_dim.insert(:age => 5, :size => 4)
        source_node = range_tree_two_dim.source_node.outgoing(:range_tree).first
        source_node['l_size'].should == 1
      end

      it "can create two parent" do
        range_tree_two_dim.insert(:age => 5, :size => 8)
        source_node = range_tree_two_dim.source_node.outgoing(:range_tree).first
        source_node['l_size'].should == 2
        child1 = source_node.outgoing(:_child_size).first
        child1['l_size'].should == 1

        leaf = child1.outgoing(:_child_size).first
        leaf['l_size'].should == 0
      end

      it "can create parents for each dimension" do
        range_tree_two_dim.insert(:age => 7, :size => 4)
        source_node = range_tree_two_dim.source_node.outgoing(:range_tree).first
        source_node['l_age'].should == 1
        source_node['l_size'].should == 1

        source_node.should have_outgoing(:_child_size)
        size_child = source_node.outgoing(:_child_size).first
        size_child['l_age'].should == 1
        size_child['l_size'].should == 0

        size_child.should have_outgoing(:_child_age)
        age_child = source_node.outgoing(:_child_age).first
        age_child['l_age'].should == 0
        age_child['l_size'].should == 0
      end
    end
  end

  describe "include_item?" do

    before do
      range_tree_two_dim.create_first({:age => 42, :size => 10})
    end

    it "should include" do
      range_tree_two_dim.include_item?({:age => 42, :size => 10}).should be_true
      range_tree_two_dim.include_item?({:age => 42.1, :size => 10.2}).should be_true
    end

    it "should not include value outside the range" do
      range_tree_two_dim.include_item?({:age => 43.1, :size => 10.2}).should be_false
      range_tree_two_dim.include_item?({:age => 42.1, :size => 11.2}).should be_false
    end

  end


  describe "create_parent" do
    context "parents for :age" do
      let(:child) do
        range_tree_two_dim.create_first({:age => 5, :size => 2})
      end

      let(:parent) do
        range_tree_two_dim.create_parent(:age, child)
      end

      it "level should be increased by one" do
        parent['l_age'].should == 1
      end

      it "should have the same properties as the children except the level" do
        parent['l_size'].should == child['l_size']
        parent['i_size'].should == child['i_size']
        parent['i_age'].should == child['i_age']
      end

      it "has a relationship between the child and parent" do
        parent.should have_outgoing(:_child_age)
        parent.outgoing(:_child_age).should include(child)
      end
    end

  end

  describe "insert_first" do

    context "first index node" do
      let!(:first_index_node) do
        @first = range_tree_two_dim.create_first({:age => 42, :size => 10})
      end

      it "creates a relationship between the source_node and the first index node" do
        source_node.should have_outgoing(:range_tree)
        source_node.outgoing(:range_tree).should include(first_index_node)
      end

      it "has an index on age" do
        first_index_node['i_age'].should == 0
      end

      it "has an index on size" do
        first_index_node['i_size'].should == 0
      end

      it "has level 0 for age" do
        first_index_node['l_age'].should == 0
      end

      it "has level 0 for size" do
        first_index_node['l_size'].should == 0
      end

      it "is the same as the current index node" do
        first_index_node.should == range_tree_two_dim.root
      end
    end

  end

end
