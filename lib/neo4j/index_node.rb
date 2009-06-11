module Neo4j

  class IndexNode
    include NodeMixin
    extend Neo4j::TransactionalMixin


    # Connects the given node with the reference node.
    # The type of the relationship will be the same as the class name of the
    # specified node unless the optional parameter type is specified.
    # This method is used internally to keep a reference to all node instances in the node space
    # (useful for example for reindexing all nodes by traversing the node space).
    #
    # ==== Parameters
    # node<Neo4j::NodeMixin>:: Connect the reference node with this node
    # type<String>:: Optional, the type of the relationship we want to create
    #
    # ==== Returns
    # nil
    #
    # :api: private
    def connect(node, type = node.class.root_class)
      rtype = Neo4j::Relations::RelationshipType.instance(type)
      @internal_node.createRelationshipTo(node.internal_node, rtype)
      nil
    end

    def on_node_created(node)
      # we have to avoid connecting to our self
      connect(node) unless self == node
    end

    def self.on_neo_started(neo_instance)
      return if neo_instance.ref_node.relation?(:index_node)
      @index_node = IndexNode.new # cache this so we do not have to look it up always
      neo_instance.ref_node.add_relation(@index_node, :index_node)
      Neo4j.event_handler.add(@index_node)
    end

    def self.on_neo_stopped(neo_instance)
      # unregister the instance
      Neo4j.event_handler.remove(@index_node)
      @index_node = nil
    end

    def self.instance
      @index_node
    end

    transactional :connect
  end


  # Add this so it can add it self as listener
  Neo4j.event_handler.add(IndexNode)

end