Rails.application.routes.draw do
  scope '/:foodcoop' do
    get '/login/demo', controller: 'demo', action: 'autologin'
  end
end
