class ActionController::Base
  @@cached_embeded = {}
  cattr_accessor :cached_embeded

  def self.caches_embeded(*actions)
    return unless perform_caching
    actions.each do |action|
      cached_embeded[action.to_sym] = true
    end
  end

  def cache_embeded?(options)
    cache_this_instance = options.delete :caching # the rest of the request processing code doesn't have to know about this option

    return false unless self.perform_caching
    
    if embeded_class(options).cached_embeded[options[:action].to_sym]
      return true unless cache_this_instance == false
    end
    return cache_this_instance
  end

  def expire_embeded(options)
    expire_fragment(options)
  end
  
  def embed_action_as_string_with_caching(options)
    return embed_action_as_string_without_caching(options) unless self.cache_embeded?(options)

    unless cached = send(:read_fragment, options)
      cached = embed_action_as_string_without_caching(options)
      if (cached.exception_rescued rescue false)  # rescue NoMethodError
        RAILS_DEFAULT_LOGGER.debug "Embeded action was not cached because it resulted in an error"
      else
        send(:write_fragment, options, cached)
      end
    end

    cached
  end

  alias_method :embed_action_as_string_without_caching, :embed_action_as_string
  alias_method :embed_action_as_string, :embed_action_as_string_with_caching  
end
