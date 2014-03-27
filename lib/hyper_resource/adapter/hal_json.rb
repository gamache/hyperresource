require 'rubygems' if RUBY_VERSION[0..2] == '1.8'
require 'json'

class HyperResource
  class Adapter

    ## HyperResource::Adapter::HAL_JSON provides support for the HAL+JSON
    ## hypermedia format by implementing the interface defined in
    ## HyperResource::Adapter.

    class HAL_JSON < Adapter
      class << self

        def serialize(object)
          JSON.dump(object)
        end

        def deserialize(string)
          JSON.parse(string)
        end

        def apply(response, resource, opts={})
          if !response.kind_of?(Hash)
            raise ArgumentError, "'response' argument must be a Hash (got #{response.inspect})"
          end
          if !resource.kind_of?(HyperResource)
            raise ArgumentError, "'resource' argument must be a HyperResource (got #{resource.inspect})"
          end

          apply_objects(response, resource)
          apply_links(response, resource)
          apply_attributes(response, resource)
          resource.loaded = true
          resource.href = response['_links']['self']['href'] rescue nil
          resource
        end

        def get_data_type(response_hash)
          response_hash['_data_type']
        end


      private

        def apply_objects(resp, rsrc)
          return unless resp['_embedded']
          objs = rsrc.objects

          resp['_embedded'].each do |name, collection|
            if collection.is_a? Hash
              objs[name] =
                rsrc.new_from(:resource => rsrc,
                              :body => collection,
                              :href => collection['_links']['self']['href'] )
            else
              objs[name] = collection.map do |obj|
                rsrc.new_from(:resource => rsrc,
                              :body => obj,
                              :href => obj['_links']['self']['href'] )
              end
            end
          end
        end


        def apply_links(resp, rsrc)
          return unless resp['_links']
          links = rsrc.links

          resp['_links'].each do |rel, link_spec|
            if link_spec.is_a? Array
              links[rel] = link_spec.map do |link|
                new_link_from_spec(rsrc, link)
              end
            else
              links[rel] = new_link_from_spec(rsrc, link_spec)
            end
          end
        end

        def new_link_from_spec(resource, link_spec)
          resource.class::Link.new(resource, link_spec)
        end


        def apply_attributes(resp, rsrc)
          given_attrs = resp.reject{|k,v| %w(_links _embedded).include?(k)}
          filtered_attrs = rsrc.incoming_body_filter(given_attrs)

          filtered_attrs.keys.each do |attr|
            rsrc.attributes[attr] = filtered_attrs[attr]
          end

          rsrc.attributes._hr_clear_changed
        end

      end
    end
  end
end

