module ActionController  #:nodoc:
  # Embedded Actions are just like regular actions, but they are referenced from
  # inside other actions, or rather, inside other views.
  # They are similar to a partial, but preceded by the execution of an action.

  module EmbeddedActions
    def self.included(base) # :nodoc:
      base.send :include, InstanceMethods
      base.extend(ClassMethods)

      base.helper do
        def embed_action(options)
          @controller.send(:embed_action_as_string, options)
        end
      end

      # If this controller was instantiated to process an embedded request,
      # +parent_controller+ points to the instantiator of this controller.
      base.send :attr_accessor, :parent_controller

      base.class_eval do
        alias_method :process_cleanup_without_embedded, :process_cleanup
        alias_method :process_cleanup, :process_cleanup_with_embedded

        alias_method :set_session_options_without_embedded, :set_session_options
        alias_method :set_session_options, :set_session_options_with_embedded

        alias_method :flash_without_embedded, :flash
        alias_method :flash, :flash_with_embedded

        alias_method :embedded_request?, :parent_controller
      end
    end

    module ClassMethods
      # Track parent controller to identify embedded requests
      def process_with_embedded(request, response, parent_controller = nil) #:nodoc:
        controller = new
        controller.parent_controller = parent_controller
        controller.process(request, response)
      end
    end

    module InstanceMethods
      # Extracts the action_name from the request parameters and performs that action.
      def process_with_embedded(request, response, method = :perform_action, *arguments) #:nodoc:
        flash.discard if embedded_request?
        process_without_embedded(request, response, method, *arguments)
      end

      protected
        # Renders the embedded action specified as the response for the current method
        def embed_action(options) #:doc:
          embedded_logging(options) do
            render_text(embedded_response(options, true).body, response.headers["Status"])
          end
        end

        # Returns the embedded action response as a string
        def embed_action_as_string(options) #:doc:
          embedded_logging(options) do
            response = embedded_response(options, false)

            if redirected = response.redirected_to
              embed_action_as_string(redirected)
            else
              response.body
            end
          end
        end

        def flash_with_embedded(refresh = false) #:nodoc:
          if @flash.nil? || refresh
            @flash =
              if @parent_controller
                @parent_controller.flash
              else
                flash_without_embedded
              end
          end

          @flash
        end

      private
        def embedded_response(options, reuse_response)
          klass    = embedded_class(options)
          request  = request_for_embedded(klass.controller_name, options)
          response = reuse_response ? @response : @response.dup

          klass.process_with_embedded(request, response, self)
        end

        # determine the controller class for the embedded action request
        def embedded_class(options)
          if controller = options[:controller]
            controller.is_a?(Class) ? controller : "#{controller.camelize}Controller".constantize
          else
            self.class
          end
        end

        # Create a new request object based on the current request.
        # The new request inherits the session from the current request,
        # bypassing any session options set for the embedded action controller's class
        def request_for_embedded(controller_name, options)
          request         = @request.dup
          request.session = @request.session

          request.instance_variable_set(
            :@parameters,
            (options[:params] || {}).with_indifferent_access.update(
              "controller" => controller_name, "action" => options[:action], "id" => options[:id]
            )
          )

          request
        end

        def embedded_logging(options)
          if logger
            logger.info "Start rendering embedded action (#{options.inspect}): "
            result = yield
            logger.info "\n\nEnd of embedded action rendering"
            result
          else
            yield
          end
        end

        def set_session_options_with_embedded(request)
          set_session_options_without_embedded(request) unless embedded_request?
        end

        def process_cleanup_with_embedded
          process_cleanup_without_embedded unless embedded_request?
        end
    end
  end

  # Psst... psst... the emperor has no clothes
end
