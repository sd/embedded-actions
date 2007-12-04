module ActionController
  module CachesEmbedded
    def self.included(base) # :nodoc:
      base.send :cattr_accessor, :cached_embedded
      base.send :cattr_accessor, :cached_embedded_options
      base.cached_embedded = {}
      base.cached_embedded_options = {}

      base.send :include, InstanceMethods
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :embed_action_as_string, :caching
      end
    end
    
    module ClassMethods
      def caches_embedded(*actions)
        return unless perform_caching
        
        options = actions.pop if actions.last.kind_of?(Hash)
        
        actions.each do |action|
          action_key = "#{controller_path}/#{action}".to_sym
          self.cached_embedded[action_key] = true
          self.cached_embedded_options[action_key] = options if options
        end
      end
    end
    
    module InstanceMethods
      def cache_embedded?(options)
        cache_this_instance = options[:params] && options[:params].delete(:caching) # the rest of the request processing code doesn't have to know about this option
        return false unless self.perform_caching
    
        if embedded_class(options).cached_embedded["#{embedded_class(options).controller_path}/#{options[:action]}".to_sym]
          return true unless cache_this_instance == false
        end

        return cache_this_instance
      end

      def expire_embedded(options)
        expire_fragment(options)
      end
  
      def embed_action_as_string_with_caching(options)
        force_refresh = options[:params] && options[:params].delete(:refresh_cache)
        return embed_action_as_string_without_caching(options) unless self.cache_embedded?(options)

        unless not force_refresh and cached = send(:read_fragment, options)
          cached = embed_action_as_string_without_caching(options)
          if (cached.exception_rescued rescue false)  # rescue NoMethodError
            RAILS_DEFAULT_LOGGER.debug "Embedded action was not cached because it resulted in an error"
          else
            cache_options = self.cached_embedded_options["#{embedded_class(options).controller_path}/#{options[:action]}".to_sym] or nil
            send(:write_fragment, options, cached, cache_options)
          end
        end

        cached
      end
    end
  end
end
