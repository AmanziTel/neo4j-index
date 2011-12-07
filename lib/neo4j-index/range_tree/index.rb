module Neo4jIndex
  module RangeTree
    class Index
      include Neo4j::NodeMixin

      property :indexed_props

      def init_on_create(props)
        super()
        self.indexed_props = props.keys.map(&:to_s)
        @definition = props  # TODO, should load this when
      end


      def granularity(prop)
        @definition[prop][:granularity]
      end

      def cluster(prop)
        @definition[prop][:cluster]
      end

    end
  end
end
