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
            raise ArgumentError, "'response' argument must be a Hash"
          end
          if !resource.kind_of?(HyperResource)
            raise ArgumentError, "'resource' argument must be a HyperResource"
          end

          apply_objects(response, resource)
          apply_links(response, resource)
          apply_attributes(response, resource)
          resource.loaded = true
          resource.href = response['_links']['self']['href'] rescue nil
          resource
        end


      private

        def apply_objects(resp, rsrc)
          return unless resp['_embedded']
          rc = rsrc.class
          rsrc.objects = rc::Objects.new(rsrc)
          objs = rsrc.objects

          resp['_embedded'].each do |name, collection|
            if collection.is_a? Hash
              r = rc.new(:root => rsrc.root,
                         :headers => rsrc.headers,
                         :namespace => rsrc.namespace)
              r.body = collection
              objs[name] = apply(collection, r)
            else
              objs[name] = collection.map do |obj|
                r = rc.new(:root => rsrc.root,
                           :headers => rsrc.headers,
                           :namespace => rsrc.namespace)
                r.body = obj
                apply(obj, r)
              end
            end
          end
        end


        def apply_links(resp, rsrc)
          return unless resp['_links']
          rsrc.links = rsrc._hr_response_class::Links.new(rsrc)
          links = rsrc.links

          resp['_links'].each do |rel, link_spec|
            keys = [rel]
            if m=rel.match(/.+:(.+)/)
              keys << m[1]
            end
            keys.each do |key|
              if link_spec.is_a? Array
                links[key] = link_spec.map do |link|
                  new_link_from_spec(rsrc, link)
                end
              else
                links[key] = new_link_from_spec(rsrc, link_spec)
              end
            end
          end
        end

        def new_link_from_spec(resource, link_spec)
          resource.class::Link.new(resource, link_spec)
        end


        def apply_attributes(resp, rsrc)
          rsrc.attributes = rsrc._hr_response_class::Attributes.new(rsrc)

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

