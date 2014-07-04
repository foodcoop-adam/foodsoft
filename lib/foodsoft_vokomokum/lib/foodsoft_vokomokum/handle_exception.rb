ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :handle_exception, FoodsoftVokomokum::VokomokumException, key: 'errors.general_msg'
end
