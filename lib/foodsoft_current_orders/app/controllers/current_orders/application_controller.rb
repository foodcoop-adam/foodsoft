class CurrentOrders::ApplicationController < ::ApplicationController
  private

  def update_base_unit
    session[:base_unit] = params[:base_unit]=='true' if params[:base_unit].present?
    @base_unit = session[:base_unit]
  end
end
