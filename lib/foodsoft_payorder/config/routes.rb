Rails.application.routes.draw do
  scope '/:foodcoop' do
    post '/group_orders/current/confirm', controller: 'payorders', action: 'confirm', as: 'confirm_group_orders'
  end
end
