Rails.application.routes.draw do
  scope '/:foodcoop' do
    get '/login/userinfo' => 'userinfo#userinfo'
  end
end
