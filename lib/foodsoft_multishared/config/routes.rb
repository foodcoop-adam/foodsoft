Rails.application.routes.draw do
  scope '/:foodcoop' do
    get '/orders/:id/foodcoop_doc', controller: 'multishared_orders', action: 'foodcoop_doc'
  end
end
