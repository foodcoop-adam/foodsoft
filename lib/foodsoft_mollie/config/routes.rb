Rails.application.routes.draw do
  scope '/:foodcoop' do
    namespace :payments do
      resource :mollie, controller: 'mollie_ideal', only: [:new, :create] do
        post :check
        get :result
        get :cancel
      end
    end
  end
end
