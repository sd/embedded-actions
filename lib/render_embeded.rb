module ActionController  #:nodoc:
  # Embeded Actions are just like regular actions, but they are referenced from
  # inside other actions, or rather, inside other views.
  # They are similar to a partial, but preceded by the execution of an action.

  module EmbededActions
    def self.included(base) # :nodoc:
      base.send :include, InstanceMethods
      base.extend(ClassMethods)

      base.helper do
        def render_embeded(options)
          @controller.send(:render_embeded_as_string, options)
        end
      end

      # If this controller was instantiated to process an embeded request,
      # +parent_controller+ points to the instantiator of this controller.
      base.send :attr_accessor, :parent_controller

      base.class_eval do
        alias_method :process_cleanup_without_embeded, :process_cleanup
        alias_method :process_cleanup, :process_cleanup_with_embeded

        alias_method :set_session_options_without_embeded, :set_session_options
        alias_method :set_session_options, :set_session_options_with_embeded

        alias_method :flash_without_embeded, :flash
        alias_method :flash, :flash_with_embeded

        alias_method :embeded_request?, :parent_controller
      end
    end

    module ClassMethods
      # Track parent controller to identify embeded requests
      def process_with_embeded(request, response, parent_controller = nil) #:nodoc:
        controller = new
        controller.parent_controller = parent_controller
        controller.process(request, response)
      end
    end

    module InstanceMethods
      # Extracts the action_name from the request parameters and performs that action.
      def process_with_embeded(request, response, method = :perform_action, *arguments) #:nodoc:
        flash.discard if embeded_request?
        process_without_embeded(request, response, method, *arguments)
      end

      protected
        # Renders the embeded action specified as the response for the current method
        def render_embeded(options) #:doc:
          embeded_logging(options) do
            render_text(embeded_response(options, true).body, response.headers["Status"])
          end
        end

        # Returns the embeded action response as a string
        def render_embeded_as_string(options) #:doc:
          embeded_logging(options) do
            response = embeded_response(options, false)

            if redirected = response.redirected_to
              render_embeded_as_string(redirected)
            else
              response.body
            end
          end
        end

        def flash_with_embeded(refresh = false) #:nodoc:
          if @flash.nil? || refresh
            @flash =
              if @parent_controller
                @parent_controller.flash
              else
                flash_without_embeded
              end
          end

          @flash
        end

      private
        def embeded_response(options, reuse_response)
          klass    = embeded_class(options)
          request  = request_for_embeded(klass.controller_name, options)
          response = reuse_response ? @response : @response.dup

          klass.process_with_embeded(request, response, self)
        end

        # determine the controller class for the embeded action request
        def embeded_class(options)
          if controller = options[:controller]
            controller.is_a?(Class) ? controller : "#{controller.camelize}Controller".constantize
          else
            self.class
          end
        end

        # Create a new request object based on the current request.
        # The new request inherits the session from the current request,
        # bypassing any session options set for the embeded action controller's class
        def request_for_embeded(controller_name, options)
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

        def embeded_logging(options)
          if logger
            logger.info "Start rendering embeded action (#{options.inspect}): "
            result = yield
            logger.info "\n\nEnd of embeded action rendering"
            result
          else
            yield
          end
        end

        def set_session_options_with_embeded(request)
          set_session_options_without_embeded(request) unless embeded_request?
        end

        def process_cleanup_with_embeded
          process_cleanup_without_embeded unless embeded_request?
        end
    end
  end

  # Psst... psst... the emperor has no clothes
end

class ActionController::Base
  include ::ActionController::EmbededActions
end
