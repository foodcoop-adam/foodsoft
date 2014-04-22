class MultisharedSessionsController < SessionsController

  skip_before_filter :select_foodcoop

  def create
    user = User.authenticate(params[:nick], params[:password])
    if user and user.ordergroup
      FoodsoftConfig.select_foodcoop user.ordergroup.scope
    elsif user
      flash.now.alert = I18n.t('multishared_signup.error_no_ordergroup')
      render 'new'
      return
    end
    super
  end
end
