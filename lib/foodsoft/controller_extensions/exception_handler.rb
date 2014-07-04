module Foodsoft::ControllerExtensions
  # Friendly error pages
  #
  # This is included in the {ApplicationController}, giving it the class method
  # +handle_exception+, which works like +rescue_from+ but has a default implementation
  # in rendering a page using the layout for HTML responses and rendering a JSON string
  # for Javascript responses (which integrations with jQuery's +ajaxError()+ handler).
  #
  #     class ApplicationController < ActionController::Base
  #       include Foodsoft::ControllerExtensions::ExceptionHandler
  #
  #       # render default template +errors/default+ with message from I18n key +errors.my+
  #       handle_exception MyException, key: 'errors.my'
  #
  #       # render template +errors/sheep+ for +SheepException+.
  #       handle_exception SheepException, template: 'sheep', status: 502
  #
  #       ...
  #     end
  #
  module ExceptionHandler
    extend ActiveSupport::Concern

    included do
      # Pass exception to client instead of giving an error
      # @param exception_cls [Class] Exception to rescue
      # @option options [Number] :status HTTP status code to return
      # @option options [String] :key I18n key for message
      # @option options [String] :template Template to render (in +errors/)
      def self.handle_exception(exception_cls, options = {})
        rescue_from exception_cls do |e|
          render_exception(e, options)
        end
      end
    end

    private

    def render_exception(e, options = {})
      @error_message = I18n.t(options[:key] || 'errors.general', msg: e.message)
      @error_status = options[:status] || 500
      respond_to do |format|
        format.html do
          render "errors/#{options[:template] || 'default'}", status: @error_status
        end
        format.js do
          render json: {error: @error_message, status: @error_status}, status: @error_status
        end
      end
    end

  end
end
