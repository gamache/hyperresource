class HyperResource
  class Adapter
    class << self

      ## Serialize the object into a string.
      def serialize(object)
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

      ## Deserialize a string into an object.
      def deserialize(string)
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

      ## Apply a response object (generally parsed JSON or XML) to the given
      ## HyperResource object.  Returns the updated resource.
      def apply(object, resource, opts={})
        raise NotImplementedError, "This is an abstract method -- subclasses "+
          "of HyperResource::Adapter must implement it."
      end

    end
  end
end
