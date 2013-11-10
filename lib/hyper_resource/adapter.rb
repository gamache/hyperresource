class HyperResource

  ## HyperResource::Adapter is the interface/abstract base class for 
  ## adapters to different hypermedia formats (e.g., HAL+JSON).  New
  ## adapters must implement the public methods of this class.

  class Adapter
    class << self

      ## Serialize the given object into a string.
      def serialize(object)
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

      ## Deserialize a given string into an object (Hash).
      def deserialize(string)
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

      ## Use a given deserialized response object (Hash) to update a given
      ## resource (HyperResource), returning the updated resource.
      def apply(response, resource, opts={})
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

    end
  end
end
