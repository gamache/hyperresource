module HyperResource::Modules
  module InternalAttributes

    ## TODO: refactor into static accessor methods, to support RubyMotion

    def self.included(base)
      base.extend(ClassMethods)
      base._hr_class_attributes.each do |attr| 
        base._hr_class_attribute attr
      end
      (base._hr_attributes & base._hr_class_attributes).each do |attr|
         base._hr_fallback_attribute attr
      end
      (base._hr_attributes - base._hr_class_attributes).each do |attr|
         base.send(:attr_accessor, attr)
      end
    end

    module ClassMethods

      def _hr_class_attributes # @private
        [ :root,             ## e.g. 'https://example.com/api/v1'
          :auth,             ## e.g. {:basic => ['username', 'password']}
          :headers,          ## e.g. {'Accept' => 'application/vnd.example+json'}
          :namespace,        ## e.g. 'ExampleAPI', or the class ExampleAPI itself
          :adapter           ## subclass of HR::Adapter
        ]
      end

      def _hr_attributes # @private
        [ :root,
          :href,
          :auth,
          :headers,
          :namespace,
          :adapter,

          :request,
          :response,
          :deserialized_response,

          :attributes,
          :links,
          :objects,

          :loaded
        ]
      end

    end # ClassMethods

  end
end

