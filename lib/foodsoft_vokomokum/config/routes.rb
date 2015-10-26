Rails.application.routes.draw do
  scope '/:foodcoop' do
    get '/login/vokomokum', controller: 'vokomokum', action: 'login'
    get '/finance/vokomokum_export_amounts', controller: 'vokomokum', action: 'export_amounts'
    post '/finance/vokomokum_send_payment_reminders', controller: 'vokomokum', action: 'send_payment_reminders'
  end
end
