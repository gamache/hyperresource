require 'uri'
require 'FuzzyURL'

class HyperResource

  ## HyperResource::Configuration is a class which implements a hostmask-
  ## scoped set of configurations.  Key/value pairs are stored under hostmasks
  ## like 'api.example.com:8080', 'api.example.com', '*.example.com', or '*'.
  ## Values are retrieved using a hostname and a key, preferring more specific
  ## hostmasks when more than one matching hostmask and key are present.
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

    ## Merges a given Configuration with this one.  Deep-merges config
    ## attributes correctly.
    def merge(new)
      merged_cfg = {}
      new_cfg = new.send(:cfg)

      (new_cfg.keys | cfg.keys).each do |mask|
        new_cfg_attrs = new_cfg[mask] || {}
        cfg_attrs = cfg[mask] || {}
        merged_cfg[mask] = {}

        ## Do a hash merge when it makes sense, except when it doesn't.
        (new_cfg_attrs.keys | cfg_attrs.keys).each do |attr|
          if !(%w(namespace adapter).include?(attr)) &&
             ((!cfg_attrs[attr] || cfg_attrs[attr].kind_of?(Hash)) &&
              (!new_cfg_attrs[attr] || new_cfg_attrs[attr].kind_of?(Hash)))
            merged_cfg[mask][attr] =
              (cfg_attrs[attr] || {}).merge(new_cfg_attrs[attr] || {})
          else
            merged_cfg[mask][attr] = new_cfg_attrs[attr] || cfg_attrs[attr]
          end
        end
      end
      self.class.new(merged_cfg)
    end

    ## Applies a given Configuration on top of this one.
    def merge!(new)
      initialize_copy(merge(new))
    end

    ## Applies a given Hash of configurations on top of this one.
    def config(hash)
      merge!(self.class.new(hash))
    end

    ## Returns this object as a Hash.
    def as_hash
      clone.send(:cfg)
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

    ## Sets a key and value pair, using the given URL as the basis of the
    ## hostmask.  Path, query, and fragment are ignored.
    def set_for_url(url, key, value)
      furl = FuzzyURL.new(url || '*')
      furl.path = nil
      furl.query = nil
      furl.fragment = nil
      set(furl.to_s, key, value)
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
          if value.kind_of?(Array) || value.kind_of?(Hash)
            value = value.clone
          end
          new_subcfg[key] = value
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
    def get_possible_masks_for_host(host, port=80, masks=nil)
      masks ||= ["#{host}:#{port}", host]  ## exact matches first
      host_parts = host.split('.')

      if host_parts.count < 2
        masks << '*' ## wildcard match last
      else
        parent_domain = host_parts[1..-1].join('.')
        masks << '*.' + parent_domain
        get_possible_masks_for_host(parent_domain, port, masks)
      end
    end

    ## Returns hostmasks from our config which match the given url.
    def matching_masks_for_url(url)
      url = url.to_s
      return ['*'] if !url || cfg.keys.count == 1
      @masks ||= {} ## key = mask string, value = FuzzyURL
      cfg.keys.each {|key| @masks[key] ||= FuzzyURL.new(key) }

      ## Test for matches, and sort by score.
      scores = {}
      cfg.keys.each {|key| scores[key] = @masks[key].match(url) }
      scores = Hash[ scores.select{|k,v| v} ] # remove nils
      scores.keys.sort_by{|k| [-scores[k], -k.length]} ## TODO length is cheesy
    end

  end

end

