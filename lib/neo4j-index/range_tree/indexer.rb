module Neo4jIndex
  module RangeTree
    class Indexer

      attr_reader :granularity, :scale, :property, :origin

      def initialize(index_node, property, granularity = 1, scale = 10)
        @granularity = granularity
        @scale = scale
        @child_rel = "_rangetree_#{property}".to_sym
        @property = property
        @index_node = index_node
        @origin = index_node[:"rangetree_origin_#{property}"]
      end

      def step_size(level)
        @granularity * @scale ** level
      end

      def origin=(value)
        @origin = @index_node[:"rangetree_origin_#{property}"] = value
      end

      def index_value_for(level, value)
        ss = step_size(level)
        ((value.to_f - @origin + ss/2) / ss).floor
      end


      def value_for(level, index_value)
        ss = step_size(level)
        (@origin - ss/2) + index_value * ss
      end

      def min_value_for(level, index_value)
        ss = step_size(level)
        (index_value - 1) * ss
      end

      def bounding_box_for(level, index_value)
        [value_for(level, index_value), value_for(level, index_value + 1) ]
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
        parent = create_index_node(child[:index_value], level)
        Neo4j::Relationship.new(@child_rel, parent, child)
#        puts "  create_parent #{level} rel '#{@child_rel}' between #{parent.neo_id} and #{child.neo_id}"
        parent
      end


      def create_first(value)
        @origin ||= @index_node[:"rangetree_origin_#{property}"] = value
        create_index_node(0, index_value_for(0, value))
      end

      def find_parent(index_node)
        index_node._node(:incoming, @child_rel)
      end

      def find_children(index_node)
        index_node._rels(:outgoing, @child_rel).collect { |r| r._end_node }
      end

      def find_or_create_parent(item, start_node)
        curr = start_node
        value = item[@property]

        while (!include_value?(curr, value))
          curr = find_parent(curr) || create_parent(curr)
        end
        curr
      end

      def include_value?(curr, value)
        level = curr[:level]
        index_value_for(level, value) == curr[:index_value]
        #puts "include_value #{value}, #{index_value_for(level, value) } == #{curr[:index_value]} lv: #{level}, #{x} - bounding #{bounding_box_for(level, index_value_for(level, value)).inspect} : #{bounding_box_for(level, curr[:index_value]).inspect}"
        #x
      end

    end
  end
end