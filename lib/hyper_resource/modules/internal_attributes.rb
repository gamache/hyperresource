module HyperResource::Modules
  module InternalAttributes

    def self.included(base)
      base.extend(ClassMethods)

      base._hr_class_attributes.each do |attr|
        base._hr_class_attribute attr
      end

      (base._hr_attributes - base._hr_class_attributes).each do |attr|
         base.send(:attr_accessor, attr)
      end

      ## Fallback attributes fall back from instance to class.
      (base._hr_attributes & base._hr_class_attributes).each do |attr|
         base._hr_fallback_attribute attr
      end
    end

    module ClassMethods

      def _hr_class_attributes # @private
        [ :root,             ## e.g. 'https://example.com/api/v1'
          :auth,             ## e.g. {:basic => ['username', 'password']}
          :headers,          ## e.g. {'Accept' => 'application/vnd.example+json'}
          :namespace,        ## e.g. 'ExampleAPI', or the class ExampleAPI itself
          :adapter,          ## subclass of HR::Adapter
          :faraday_options   ## e.g. {:request => {:timeout => 30}}
        ]
      end

      def _hr_attributes # @private
        [ :root,
          :href,
          :auth,
          :headers,
          :namespace,
          :adapter,
          :faraday_options,

          :request,
          :response,
          :body,

          :attributes,
          :links,
          :objects,

          :loaded
        ]
      end

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

    end # ClassMethods

  end
end

