module Neo4jIndex
  module RangeTree
    class Index
      attr_reader :indexers, :root, :source_node

      def initialize(source_node, index_spec)
        @indexers = {}
        index_spec.keys.each do |key|
          @indexers[key] = Indexer.new(source_node, key, index_spec[key][:granularity], index_spec[key][:cluster])
        end

        @source_node = source_node
      end

      def indexed_props
        @indexers.keys
      end

      def create_first(item)
        props = {}
        @indexers.each_pair do |key, indexer|
          value = item[key]
          indexer.origin = value
          props["l_#{key}"] = 0
          props["i_#{key}"] = 0
        end
        @root = Neo4j::Node.new(props)
        Neo4j::Relationship.new(:range_tree, @source_node, @root)
        @root
      end


      def create_parent(key, child)
        indexer = @indexers[key]
        props = child.props
        props["l_#{key}"] += 1
        props.delete('_neo_id')
        parent = Neo4j::Node.new(props)
        Neo4j::Relationship.new("_child_#{key}", parent, child)
        parent
      end

      # creates all parents for all  properties we should index
      def create_all_parents(item, child)
        curr_parent = child
        while (key = find_first_none_matching_index_key(item, curr_parent))
          curr_parent = create_parent(key, curr_parent)
        end

        # if the child was the root then we need to replace the root
        puts "create_all_parents root: #{@root.props.inspect}, child = #{child.props.inspect}, curr_parent = #{curr_parent.props.inspect}"
        if @root == child && curr_parent != child
          rel = @source_node._rel(:outgoing, :range_tree)
          rel.del
          @root = curr_parent
          Neo4j::Relationship.new(:range_tree, @source_node, @root)
          puts "New root #{@root.props.inspect}"
        end
      end

      def find_first_none_matching_index_key(item, index_node = @root)
        @indexers.keys.find do |key|
          indexer = @indexers[key]
          key = indexer.property
          level = index_node["l_#{key}"]
          value = item[key]
          index_value = indexer.index_value_for(level, value)
          index_node["i_#{key}"] != index_value
        end
      end

      def include_item?(item, index_node = @root)
        ! find_first_none_matching_index_key(item, index_node)
      end

      def insert(item)
        if @root
          # does current index node include the value ?
          create_all_parents(item, @root)
        else
          create_first(item)
        end
      end

      #def insert2(item)
      #  @indexers.each_pair do |key, indexer|
      #    value = item[key]
      #
      #    # search as high as necessary to find a index node that covers this value
      #    index_node = @root ? indexer.find_or_create_parent(value, item) : indexer.create_first(value, item)
      #
      #    # now step down building index all the way to the bottom
      #    while (index_node[:level] > 0)
      #      # First search the index node tree for existing child index nodes that match
      #      # If no child index node was found, create one and link it into the tree
      #      child = indexer.find_child(index_node, values) || indexer.create_child(index_node, values, item)
      #
      #      # Finally step down one level and repeat until we're at the bottom
      #      index_node = child
      #    end
      #
      #    indexer.add_item(index_node, item)
      #  end
      #
      #  @root = index_node
      #end

    end
  end
end
