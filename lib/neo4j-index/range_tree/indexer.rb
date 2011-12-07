module Neo4jIndex
  module RangeTree
    class Indexer

      attr_reader :granularity, :scale, :property

      def initialize(property, granularity = 1, scale = 10)
        @granularity = granularity
        @scale = scale
        @child_rel = "_rangetree_#{property}".to_sym
        @property = property
      end

      def step_size(level)
        @granularity * @scale ** level
      end

      def index_value_for(level, value)
        ss = step_size(level)
        ((value.to_f + ss/2) / ss).floor
      end

      def value_for(level, index_value)
        ss = step_size(level)
        index_value * ss - ss/2
      end

      def min_value_for(level, index_value)
        ss = step_size(level)
        (index_value - 1) * ss - ss/2
      end

      def bounding_box_for(level, index_value)
        [min_value_for(level, index_value), value_for(level, index_value)]
      end

      def create_index_node(index_value, level)
        Neo4j::Node.new(:index_value => index_value, :level => level)
      end


      #def create_child(parent, value, item)
      #  level = parent ? parent[:level] - 1 : 0
      #  child = create_index_node(index_value_for(level, value), level)
      #  parent && Neo4j::Relationship.new(@child_rel, parent, child)
      #  child
      #end

      def create_parent(child)
        level = child[:level] + 1
        puts "  create parent #{level}"
        parent = create_index_node(child[:index_value], level)
        Neo4j::Relationship.new(@child_rel, parent, child)
        parent
      end

      def find_parent(index_node)
        index_node._node(:incoming, @child_rel)
      end

      def find_or_create_parent(item, start_node)
        curr = start_node
        value = item[@property]
        level = curr[:level]

        while (index_value_for(level, value) != index_value_for(level, curr[:index_value]))
          puts "not equal #{index_value_for(level, value)} != #{index_value_for(level, curr[:index_value])}"
          level = curr[:level]
          puts "  curr #{level}, value=#{value}, curr[:index_value])#{curr[:index_value]}"
          curr = find_parent(curr) || create_parent(curr)
        end
        curr
      end

    end
  end
end