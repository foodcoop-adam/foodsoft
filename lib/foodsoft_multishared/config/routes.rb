Rails.application.routes.draw do
  scope '/:foodcoop' do
    match '/home/select_foodcoop' => 'multishared_signup#select_foodcoop'
    get '/orders/:id/foodcoop_doc', as: 'multishared_order', controller: 'multishared_orders', action: 'foodcoop_doc'
  end
end
