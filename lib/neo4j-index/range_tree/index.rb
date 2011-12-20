module Neo4jIndex
  module RangeTree
    class Index
      attr_reader :indexers

      def initialize(index_spec)
        @indexers = {}
        index_spec.keys.each do |key|
          @indexers[key] = Indexer.new(index_spec[key][:granularity], index_spec[key][:cluster])
        end
      end


      def insert_first(item)
        @indexers.each_pair do |key, indexer|
          value = item[key]
          indexer.create_first(value, item)
        end

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
