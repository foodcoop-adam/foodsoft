Rails.application.routes.draw do
  scope '/:foodcoop' do
    namespace :payments do
      scope '/adyen', as: :adyen do

        post :notify, controller: 'adyen_notifications', action: :notify

        resource :pin, controller: 'adyen_pin', only: [:new, :create] do
          get :index
          get :detect
          get :created
        end

        resource :hpp, controller: 'adyen_hpp', only: [:new, :create] do
          get :index, to: :new
          get :result
        end

      end
    end
  end
end
