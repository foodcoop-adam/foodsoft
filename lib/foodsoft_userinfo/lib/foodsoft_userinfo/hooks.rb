# adds support for a return_to parameter to login

module FoodsoftUserinfo

  # show warning on included controllers
  module LoginRedirect
    def self.included(base) # :nodoc:
      base.class_eval do
        # patch new to set the return_to session vavriable when url matches
        alias_method :foodsoft_userinfo_orig_new, :new
        def new(*args)
          unless params[:return_to].blank?
            if FoodsoftUserinfo::redirect_url_valid?(params[:return_to])
              Rails.logger.debug "Storing return_to url: #{params[:return_to]}"
              session[:return_to] = params[:return_to] 
            else
              Rails.logger.warn "Invalid return_to url: #{params[:return_to]}"
            end
          end
          foodsoft_userinfo_orig_new(*args)
        end
      end
    end
  end

  def self.redirect_url_valid?(url)
    url or return false
    allowed = FoodsoftConfig[:userinfo_return_urls] or return false
    allowed.each do |allowed_url|
      url.start_with?(allowed_url)
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  SessionsController.send :include, FoodsoftUserinfo::LoginRedirect
end
