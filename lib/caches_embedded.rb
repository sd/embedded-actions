class ActionController::Base
  @@cached_embedded = {}
  cattr_accessor :cached_embedded
  alias_method :cached_embeded, :cached_embedded

  def self.caches_embedded(*actions)
    return unless perform_caching
    actions.each do |action|
      cached_embedded[action.to_sym] = true
    end
  end

  def cache_embedded?(options)
    cache_this_instance = options.delete :caching # the rest of the request processing code doesn't have to know about this option

    return false unless self.perform_caching
    
    if embedded_class(options).cached_embedded[options[:action].to_sym]
      return true unless cache_this_instance == false
    end
    return cache_this_instance
  end

  def expire_embedded(options)
    expire_fragment(options)
  end
  
  def embed_action_as_string_with_caching(options)
    return embed_action_as_string_without_caching(options) unless self.cache_embedded?(options)

    unless cached = send(:read_fragment, options)
      cached = embed_action_as_string_without_caching(options)
      if (cached.exception_rescued rescue false)  # rescue NoMethodError
        RAILS_DEFAULT_LOGGER.debug "Embedded action was not cached because it resulted in an error"
      else
        send(:write_fragment, options, cached)
      end
    end

    cached
  end

  alias_method :embed_action_as_string_without_caching, :embed_action_as_string
  alias_method :embed_action_as_string, :embed_action_as_string_with_caching  
end
