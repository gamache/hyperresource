module HyperResource::Modules
  module Utils

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      ## Inheritable class attribute, kinda like in Rails.
      def class_attribute(*names)
        names.map(&:to_sym).each do |name|
          instance_eval <<-EOT
            def #{name}=(val)
              @#{name} = val
            end
            def #{name}
              return @#{name} if defined?(@#{name})
              return superclass.#{name} if superclass.respond_to?(:#{name})
              nil
            end
          EOT
        end
      end

      ## Instance attributes which fall back to class attributes.
      def fallback_attribute(*names)
        names.map(&:to_sym).each do |name|
          class_eval <<-EOT
            def #{name}=(val)
              @#{name} = val
            end
            def #{name}
              return @#{name} if defined?(@#{name})
              return self.class.#{name} if self.class.respond_to?(:#{name})
              nil
            end
          EOT
        end
      end

    end # module ClassMethods

  end
end
