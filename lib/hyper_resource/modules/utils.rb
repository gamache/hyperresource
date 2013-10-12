module HyperResource::Modules
  module Utils

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      ## Inheritable class attribute, kinda like in Rails.
      def _hr_class_attribute(*names)
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
      def _hr_fallback_attribute(*names)
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

      ## Show a deprecation message.
      def _hr_deprecate(message)
        STDERR.puts "#{message} (called from #{caller[2]})"
      end

    end # module ClassMethods


    def _hr_deprecate(*args); self.class._hr_deprecate(*args) end

  end
end
