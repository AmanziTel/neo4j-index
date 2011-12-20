require 'spec_helper'

describe Neo4jIndex::RangeTree::Index, :type => :transactional do

  let(:root) { Neo4j::Node.new }

  let(:range_tree_two_dim) do
    Neo4jIndex::RangeTree::Index.new(root, :age => {:granularity => 1, :cluster => 10}, :size => {:granularity => 1, :cluster => 10})
  end


  describe "create" do
    subject { range_tree_two_dim }

    its(:indexed_props) { should =~ [:age, :size]}

  end

  describe "include_item?" do

    before do
      range_tree_two_dim.insert_first({:age => 42, :size => 10})
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


  describe "insert_first" do

    context "first index node" do
      subject{ range_tree_two_dim.insert_first({:age => 42, :size => 10})}

      it "creates a relationship between the root and the first index node" do
        root.should have_outgoing(:range_tree)
        root.outgoing(:range_tree).should include(subject)
      end

      it "level is zero" do
        subject[:level] == 0
      end

      it "has an index on age" do
        subject['i_age'].should == 0
      end

      it "has an index on size" do
        subject['i_size'].should == 0
      end

      it "has level 0 for age" do
        subject['l_age'].should == 0
      end

      it "has level 0 for size" do
        subject['l_size'].should == 0
      end

      it "is the same as the current index node" do
        subject == range_tree_two_dim.current_index_node
      end
    end

  end

end
