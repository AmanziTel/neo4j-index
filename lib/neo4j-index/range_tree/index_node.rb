module Neo4jIndex
  module RangeTree
    module IndexNode
      class << self

        def create_raw(index_values, level)
          index_node = Neo4j::Node.new
          index_node[:level] = level
          index_node[:index_values] = index_values
          index_node
        end

        def create_first(indexer, values)
          create_child(nil, indexer, values)
        end

        def create_child(parent_index_node, indexer, values)
          level = parent_index_node ? parent_index_node[:level] - 1 : 0
          child_index_node = create_raw(indexer.calculate_index_values(level, values), level)
          parent_index_node && Neo4j::Relationship.new(indexer.relationship, parent_index_node, child_index_node)
          child_index_node
        end

        def create_parent(child_index_node, indexer)
          level = child_index_node[:level] + 1
          parent_index_node = create_raw(child_index_node[:index_values], level)
          Neo4j::Relationship.new(indexer.relationship, parent_index_node, child_index_node)
          parent_index_node
        end
      end
    end
  end
end
