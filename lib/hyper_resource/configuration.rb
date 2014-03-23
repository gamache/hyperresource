require 'uri'

class HyperResource

  ## HyperResource::Configuration is a class which implements a hostmask-
  ## scoped set of configurations.  Key/value pairs are stored under hostmasks
  ## like 'api.example.com', '*.example.com', or '*'.  Values are retrieved
  ## using a hostname and a key, preferring more specific hostmasks when
  ## more than one matching hostmask and key are present.
  ##
  ## HyperResource users are not expected to use this class directly.
  class Configuration

    ## Creates a new HyperResource::Configuration, with the given initial
    ## internal state if provided.
    def initialize(cfg={})
      @cfg = cfg
      @cfg['*'] ||= {}
    end

    ## Returns a deep copy of this object.
    def clone
      self.class.new.send(:initialize_copy, self)
    end

    ## Returns the value for a particular hostmask and key, or nil if not
    ## present.
    def get(mask, key)
      cfg[mask] ||= {}
      cfg[mask][key.to_s]
    end

    ## Sets a key and value pair for the given hostmask.
    def set(mask, key, value)
      cfg[mask] ||= {}
      cfg[mask][key.to_s] = value
    end

    ## Returns the best matching value for the given URL and key, or nil
    ## otherwise.
    def get_for_url(url, key)
      subconfig_for_url(url)[key.to_s]
    end

    ## Sets a key and value pair, using the given URL's hostname as the
    ## hostmask.
    def set_for_url(url, key, value)
      set(URI(url).host, key, value)
    end

  private

    def cfg
      @cfg
    end

    ## Performs a two-level-deep copy of old @cfg.
    def initialize_copy(old)
      old.send(:cfg).each do |mask, old_subcfg|
        new_subcfg = {}
        old_subcfg.each do |key, value|
          new_subcfg[key] = value.respond_to?(:clone) ? value.clone : value
        end
        @cfg[mask] = new_subcfg
      end
      self
    end

    ## Returns a merged subconfig consisting of all matching hostmask
    ## subconfigs, giving priority to more specific hostmasks.
    def subconfig_for_url(url)
      matching_masks_for_url(url).inject({}) do |subcfg, mask|
        (cfg[mask] || {}).merge(subcfg)
      end
    end

    ## Returns the hostmasks which match the given url, sorted best match
    ## first.
    def get_possible_masks_for_host(host, masks=nil)
      masks ||= [host]  ## exact match first
      host_parts = host.split('.')

      if host_parts.count < 2
        masks << '*' ## wildcard match last
      else
        parent_domain = host_parts[1..-1].join('.')
        masks << '*.' + parent_domain
        get_possible_masks_for_host(parent_domain, masks)
      end
    end

    ## Returns hostmasks from our config which match the given url.
    def matching_masks_for_url(url)
      return ['*'] if !url || @cfg.keys.count == 1
      url_host = URI(url).host
      get_possible_masks_for_host(url_host) & cfg.keys
    end

  end

end
