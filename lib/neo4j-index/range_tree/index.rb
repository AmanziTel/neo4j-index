module Neo4jIndex
  module RangeTree
    class Index
      attr_reader :indexers, :current_index_node, :root

      def initialize(root, index_spec)
        @indexers = {}
        index_spec.keys.each do |key|
          @indexers[key] = Indexer.new(root, key, index_spec[key][:granularity], index_spec[key][:cluster])
        end

        @root = root
      end

      def indexed_props
        @indexers.keys
      end

      def insert_first(item)
        props = {}
        @indexers.each_pair do |key, indexer|
          value = item[key]
          indexer.origin = value
          props["l_#{key}"] = 0
          props["i_#{key}"] = 0
        end
        @current_index_node = Neo4j::Node.new(props )
        Neo4j::Relationship.new(:range_tree, @root, @current_index_node)
        puts "Connected #{@root.neo_id} with #{@current_index_node.neo_id}"
        @current_index_node
      end


      def include_item?(item, index_node = @current_index_node)
        not_found = @indexers.values.find do |indexer|
          key = indexer.property
          level = index_node["l_#{key}"]
          value = item[key]
          index_value = indexer.index_value_for(level, value)
          puts "key=#{key}, value = #{value}, index_value #{index_value} == #{index_node["i_#{key}"]}, props: #{index_node.props.inspect}"
          index_node["i_#{key}"] != index_value
        end

        ! not_found
      end

      def find_or_create_parent(item)
        curr = @current_index_node
      end

      def insert(item)
        @indexers.each_pair do |key, indexer|
          value = item[key]

          # search as high as necessary to find a index node that covers this value
          index_node = @current_index_node ? indexer.find_or_create_parent(value, item) : indexer.create_first(value, item)

          # now step down building index all the way to the bottom
          while (index_node[:level] > 0)
            # First search the index node tree for existing child index nodes that match
            # If no child index node was found, create one and link it into the tree
            child = indexer.find_child(index_node, values) || indexer.create_child(index_node, values, item)

            # Finally step down one level and repeat until we're at the bottom
            index_node = child
          end

          indexer.add_item(index_node, item)
        end

        @current_index_node = index_node
      end

    end
  end
end
