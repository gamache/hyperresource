require 'rubygems' if RUBY_VERSION[0..2] == '1.8'
require 'json'

class HyperResource
  class Adapter

    ## HyperResource::Adapter::Siren provides support for the Siren
    ## hypermedia format by implementing the interface defined in
    ## HyperResource::Adapter.

    class Siren < Adapter
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
          resource.href = get_self_href(response)
          resource
        end

      private

        def get_self_href(response)
          response['links'].each do |link|
            return link['href'] if link['rel'].include?('self')
          end
          nil
        end

        def apply_objects(resp, rsrc)

        end

        ## Links in HyperResource map to both Links and Actions in
        ## Siren.
        def apply_links(resp, rsrc)
          rsrc.links = rsrc._hr_response_class::Links.new(rsrc)
          links = rsrc.links

          if resp['links']
            resp['links'].each do |link_spec|
              rels = Array(link_spec['rel'])
              rels.each do |rel|

                keys = [rel]
                if m=rel.match(%r{.+[:/](.+)})  ## match text after last : or /
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
          end

          if resp['actions']

          end

          links._hr_create_methods!
        end

        def new_link_from_spec(resource, link_spec)
          resource.class::Link.new(resource, link_spec)
        end

        def apply_attributes(resp, rsrc)
          rsrc.attributes = rsrc._hr_response_class::Attributes.new(rsrc)

          given_attrs = resp['properties'] || {}
          filtered_attrs = rsrc.incoming_body_filter(given_attrs)

          filtered_attrs.keys.each do |attr|
            rsrc.attributes[attr] = filtered_attrs[attr]
          end

          rsrc.attributes._hr_clear_changed
          rsrc.attributes._hr_create_methods!
        end

      end
    end
  end
end

