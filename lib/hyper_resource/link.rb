require 'uri_template'

class HyperResource::Link
  attr_accessor :base_href,
                :name,
                :templated,
                :params,
                :parent_resource

  def templated?; templated end

  def initialize(resource=nil, link_spec={})
    self.parent_resource = resource || HyperResource.new
    self.base_href = link_spec['href']
    self.name = link_spec['name']
    self.templated = !!link_spec['templated']
    self.params    = link_spec['params'] || {}
  end

  ## Returns this link's href, applying any URI template params.
  def href
    if self.templated?
      URITemplate.new(self.base_href).expand(params)
    else
      self.base_href
    end
  end

  ## Returns a new scope with the given params; that is, returns a copy of
  ## itself with the given params applied.
  def where(params)
    self.class.new(self.parent_resource,
                   'href' => self.base_href,
                   'name' => self.name,
                   'templated' => self.templated,
                   'params' => self.params.merge(params))
  end

  ## Returns a HyperResource representing this link
  def resource
    parent_resource.new_from_link(self.href)
  end

  ## Returns a HyperResource representing this link, and fetches it.
  def get
    self.resource.get
  end

  ## If we were called with a method we don't know, load this resource
  ## and pass the message along.  This achieves implicit loading.
  def method_missing(method, *args)
    self.get.send(method, *args)
  end
end
