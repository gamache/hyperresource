class HyperResource
  module Utils
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
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

      ## this is my version :nodoc:
      def class_attribute(*names)
        names.map(&:to_sym).each do |name|
          instance_eval <<-EOT
            def #{name}=(val)
              @#{name} = val
            end
            def #{name}
              @#{name} or
                superclass.respond_to?(:#{name}) && superclass.#{name} or
                nil
            end
          EOT
        end
      end
    end
  end
end
