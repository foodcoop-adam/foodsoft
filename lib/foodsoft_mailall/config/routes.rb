Rails.application.routes.draw do
  scope '/:foodcoop' do
    namespace :admin do
      get '/mailall/expand' => 'mailall#expand'
      get '/mailall' => 'mailall#show'
    end
  end
end
