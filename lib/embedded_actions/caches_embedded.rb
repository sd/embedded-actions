module ActionController
  module CachesEmbedded
    def self.included(base) # :nodoc:
      base.send :include, InstanceMethods
      base.send :cattr_accessor, :cached_embedded
      base.send :cattr_accessor, :cached_embedded_options
      base.send :cattr_accessor, :cached_embedded_engine_options
      base.cached_embedded = {}
      base.cached_embedded_options = {}
      base.cached_embedded_engine_options = {}
      
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
          if options
            options = options.dup
            self.cached_embedded_options[action_key] ||= {}
            self.cached_embedded_options[action_key][:compress] = options.delete(:compress)
            self.cached_embedded_options[action_key][:options_for_name] = options.delete(:options_for_name)
            self.cached_embedded_engine_options[action_key] = options
          end
        end
      end
    end
    
    module InstanceMethods
      def cache_embedded?(options)
        cache_this_instance = options[:params] && options[:params].delete(:caching) # the rest of the request processing code doesn't have to know about this option
        return false unless self.perform_caching
    
        controller_class = embedded_class(options)
        while controller_class
          if self.cached_embedded["#{controller_class.controller_path}/#{options[:action]}".to_sym]
            return true unless cache_this_instance == false
          end
          controller_class = controller_class.superclass
          controller_class = nil unless controller_class.respond_to? :controller_path
        end

        return cache_this_instance
      end

      def expire_embedded(options)
        expire_fragment(options)
      end
  
      def embedded_cache_name_for_options(options, options_for_name = nil)
        if options_for_name.nil?
          options_for_caching = self.cached_embedded_options["#{embedded_class(options).controller_path}/#{options[:action]}".to_sym]
          options_for_caching ||= self.cached_embedded_options["#{embedded_class(options).superclass.controller_path}/#{options[:action]}".to_sym] if embedded_class(options).superclass.respond_to? :controller_path

          options_for_name = options_for_caching && options_for_caching[:options_for_name]
        end
        
        case options_for_name
        when Hash
          extra_options_for_name = options_for_name
        when Proc
          case options_for_name.arity
          when 1
            extra_options_for_name = options_for_name.call(self)
          else
            extra_options_for_name = options_for_name.call(self, options)
          end
        else
          extra_options_for_name = nil
        end

        options = options.merge(extra_options_for_name) if extra_options_for_name
        
        options
      end
    
      def embed_action_as_string_with_caching(options)
        options = options.dup
        force_refresh = options[:params] && options[:params].delete(:refresh_cache)
        
        return embed_action_as_string_without_caching(options) unless self.cache_embedded?(options)

        options_for_caching = self.cached_embedded_options["#{embedded_class(options).controller_path}/#{options[:action]}".to_sym]
        options_for_caching ||= self.cached_embedded_options["#{embedded_class(options).superclass.controller_path}/#{options[:action]}".to_sym] if embedded_class(options).superclass.respond_to? :controller_path

        options_for_cache_engine = self.cached_embedded_engine_options["#{embedded_class(options).controller_path}/#{options[:action]}".to_sym]
        options_for_cache_engine ||= self.cached_embedded_engine_options["#{embedded_class(options).superclass.controller_path}/#{options[:action]}".to_sym] if embedded_class(options).superclass.respond_to? :controller_path
# debugger
        cache_name = embedded_cache_name_for_options(options, options_for_caching && options_for_caching[:options_for_name])

        if force_refresh
          cached = nil
        else
          cached = nil
          if options_for_caching && options_for_caching[:compress]
            cached = Zlib::Inflate.inflate(send(:read_fragment, cache_name.merge("_embedded_compression" => true))) rescue nil
          end
          
          unless cached
            cached = send(:read_fragment, cache_name)
          end
        end
        
        unless cached
          cached = embed_action_as_string_without_caching(options)
          if (cached.exception_rescued rescue false)  # rescue NoMethodError
            RAILS_DEFAULT_LOGGER.debug "Embedded action was not cached because it resulted in an error"
          else
            if options_for_caching && options_for_caching[:compress]
              send(:write_fragment, cache_name.merge("_embedded_compression" => true), Zlib::Deflate.deflate(cached), options_for_cache_engine)
            else
              send(:write_fragment, cache_name, cached, options_for_cache_engine)
            end
          end
        end
        
        cached
      end
    end
  end
end
