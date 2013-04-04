class HyperResource
  class << self
    ## swiped from https://github.com/apotonick/hooks/blob/master/lib/hooks/inheritable_attribute.rb
    def inheritable_attr(name) # :nodoc:
      instance_eval %Q{
        def #{name}=(v)
          @#{name} = v
        end

        def #{name}
          return @#{name} unless superclass.respond_to?(:#{name}) and value = superclass.#{name}
          @#{name} ||= value.clone # only do this once.
        end
      }
    end
  end
end
